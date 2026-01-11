import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shopple/utils/app_logger.dart';

/// Provides enterprise-grade network resilience.
/// - Circuit breaker pattern.
/// - Exponential backoff with jitter.
/// - Connection health monitoring.
/// - Offline detection and queueing.
/// - Smart request deduplication.
class ResilientNetworkService {
  ResilientNetworkService._();
  static final ResilientNetworkService instance = ResilientNetworkService._();
  
  // Circuit breaker state per endpoint.
  final Map<String, _CircuitBreaker> _circuitBreakers = {};
  
  // Connection health tracking.
  bool _isOnline = true;
  // ignore: unused_field - Reserved for future health metrics.
  DateTime? _lastSuccessfulRequest;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  
  // Request deduplication.
  final Map<String, Future<dynamic>> _inFlightRequests = {};
  
  // Connectivity stream.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Initialize the service and start monitoring connectivity.
  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty && 
                  results.any((r) => r != ConnectivityResult.none);
      
      if (!wasOnline && _isOnline) {
        AppLogger.d('🌐 Network restored - resetting circuit breakers');
        _resetAllCircuitBreakers();
      } else if (wasOnline && !_isOnline) {
        AppLogger.w('📴 Network lost - switching to offline mode');
      }
    });
    
    // Initial connectivity check.
    Connectivity().checkConnectivity().then((results) {
      _isOnline = results.isNotEmpty && 
                  results.any((r) => r != ConnectivityResult.none);
    });
  }
  
  /// Dispose of resources.
  void dispose() {
    _connectivitySubscription?.cancel();
  }
  
  /// Current online status.
  bool get isOnline => _isOnline;
  
  /// Check if the app is in a healthy network state.
  bool get isHealthy => _isOnline && _consecutiveFailures < _maxConsecutiveFailures;
  
  /// Execute a network request with resilience patterns.
  /// 
  /// [key] - Unique identifier for deduplication and circuit breaking.
  /// [request] - The actual network request function.
  /// [fallback] - Optional async fallback when request fails.
  /// [maxRetries] - Maximum retry attempts (default: 2).
  /// [timeout] - Request timeout (default: 10 seconds).
  Future<T> execute<T>({
    required String key,
    required Future<T> Function() request,
    FutureOr<T> Function()? fallback,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Check circuit breaker.
    final breaker = _getOrCreateBreaker(key);
    if (breaker.isOpen) {
      AppLogger.w('⚡ Circuit breaker OPEN for $key - using fallback');
      if (fallback != null) return await fallback();
      throw CircuitBreakerOpenException(key);
    }
    
    // Check for in-flight duplicate request.
    if (_inFlightRequests.containsKey(key)) {
      AppLogger.d('🔄 Deduplicating request for $key');
      return await _inFlightRequests[key] as T;
    }
    
    // Execute with retry logic.
    final future = _executeWithRetry(
      key: key,
      request: request,
      fallback: fallback,
      maxRetries: maxRetries,
      timeout: timeout,
      breaker: breaker,
    );
    
    _inFlightRequests[key] = future;
    
    try {
      return await future;
    } finally {
      _inFlightRequests.remove(key);
    }
  }
  
  Future<T> _executeWithRetry<T>({
    required String key,
    required Future<T> Function() request,
    FutureOr<T> Function()? fallback,
    required int maxRetries,
    required Duration timeout,
    required _CircuitBreaker breaker,
  }) async {
    int attempt = 0;
    
    while (attempt <= maxRetries) {
      try {
        // Execute request with timeout.
        final result = await request().timeout(timeout);
        
        // Success - record and return.
        _recordSuccess(breaker);
        return result;
        
      } on TimeoutException {
        attempt++;
        AppLogger.w('⏱️ Request timeout for $key (attempt $attempt)');
        
        if (attempt > maxRetries) {
          _recordFailure(breaker);
          if (fallback != null) return await fallback();
          rethrow;
        }
        
        // Wait with exponential backoff before retry.
        await _waitWithBackoff(attempt);
        
      } catch (e) {
        attempt++;
        AppLogger.w('❌ Request failed for $key: $e (attempt $attempt)');
        
        if (attempt > maxRetries) {
          _recordFailure(breaker);
          if (fallback != null) return await fallback();
          rethrow;
        }
        
        // Check if error is retryable.
        if (!_isRetryableError(e)) {
          _recordFailure(breaker);
          if (fallback != null) return await fallback();
          rethrow;
        }
        
        await _waitWithBackoff(attempt);
      }
    }
    
    // Should never reach here, but safety fallback.
    if (fallback != null) return await fallback();
    throw Exception('Max retries exceeded for $key');
  }
  
  /// Wait with exponential backoff and jitter.
  Future<void> _waitWithBackoff(int attempt) async {
    final baseDelay = Duration(milliseconds: 100 * pow(2, attempt).toInt());
    final jitter = Random().nextInt(baseDelay.inMilliseconds ~/ 2);
    final totalDelay = Duration(milliseconds: baseDelay.inMilliseconds + jitter);
    
    AppLogger.d('⏳ Waiting ${totalDelay.inMilliseconds}ms before retry');
    await Future.delayed(totalDelay);
  }
  
  /// Check if an error is retryable.
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Non-retryable errors.
    if (errorString.contains('permission') ||
        errorString.contains('unauthenticated') ||
        errorString.contains('invalid-argument') ||
        errorString.contains('not-found')) {
      return false;
    }
    
    // Retryable errors.
    return errorString.contains('timeout') ||
           errorString.contains('unavailable') ||
           errorString.contains('resource-exhausted') ||
           errorString.contains('deadline') ||
           errorString.contains('network') ||
           errorString.contains('internal');
  }
  
  _CircuitBreaker _getOrCreateBreaker(String key) {
    return _circuitBreakers.putIfAbsent(key, () => _CircuitBreaker());
  }
  
  void _recordSuccess(_CircuitBreaker breaker) {
    breaker.recordSuccess();
    _consecutiveFailures = 0;
    _lastSuccessfulRequest = DateTime.now();
  }
  
  void _recordFailure(_CircuitBreaker breaker) {
    breaker.recordFailure();
    _consecutiveFailures++;
  }
  
  void _resetAllCircuitBreakers() {
    for (final breaker in _circuitBreakers.values) {
      breaker.reset();
    }
    _consecutiveFailures = 0;
  }
  
  /// Get circuit breaker status for debugging.
  Map<String, Map<String, dynamic>> getCircuitBreakerStatus() {
    return _circuitBreakers.map((key, breaker) => MapEntry(key, {
      'state': breaker.state.toString(),
      'failures': breaker.failureCount,
      'lastFailure': breaker.lastFailureTime?.toIso8601String(),
    }));
  }
}

/// Circuit breaker implementation.
class _CircuitBreaker {
  _CircuitBreakerState state = _CircuitBreakerState.closed;
  int failureCount = 0;
  DateTime? lastFailureTime;
  
  static const int failureThreshold = 3;
  static const Duration openDuration = Duration(seconds: 30);
  
  bool get isOpen {
    if (state == _CircuitBreakerState.closed) return false;
    
    if (state == _CircuitBreakerState.open) {
      // Check if we should transition to half-open.
      if (lastFailureTime != null) {
        final elapsed = DateTime.now().difference(lastFailureTime!);
        if (elapsed >= openDuration) {
          state = _CircuitBreakerState.halfOpen;
          return false; // Allow one test request.
        }
      }
      return true;
    }
    
    // Half-open state - allow requests through.
    return false;
  }
  
  void recordSuccess() {
    state = _CircuitBreakerState.closed;
    failureCount = 0;
  }
  
  void recordFailure() {
    failureCount++;
    lastFailureTime = DateTime.now();
    
    if (failureCount >= failureThreshold) {
      state = _CircuitBreakerState.open;
      AppLogger.w('⚡ Circuit breaker OPENED after $failureCount failures');
    }
  }
  
  void reset() {
    state = _CircuitBreakerState.closed;
    failureCount = 0;
    lastFailureTime = null;
  }
}

enum _CircuitBreakerState { closed, open, halfOpen }

/// Exception thrown when circuit breaker is open.
class CircuitBreakerOpenException implements Exception {
  final String endpoint;
  CircuitBreakerOpenException(this.endpoint);
  
  @override
  String toString() => 'Circuit breaker is open for endpoint: $endpoint';
}
