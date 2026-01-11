import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/utils/app_logger.dart';

class MonthSummary {
  final double avgPrice;
  final String bestBuyDay;
  final double closingPrice;
  final int daysWithData;
  final double maxPrice;
  final double minPrice;
  final double openingPrice;
  final double priceRange;
  final double priceStabilityScore;
  final double priceVolatility;
  final double totalChangePercent;
  final String trendDirection;

  MonthSummary({
    required this.avgPrice,
    required this.bestBuyDay,
    required this.closingPrice,
    required this.daysWithData,
    required this.maxPrice,
    required this.minPrice,
    required this.openingPrice,
    required this.priceRange,
    required this.priceStabilityScore,
    required this.priceVolatility,
    required this.totalChangePercent,
    required this.trendDirection,
  });

  factory MonthSummary.fromFirestore(Map<String, dynamic> data) {
    return MonthSummary(
      avgPrice: (data['avg_price'] ?? 0).toDouble(),
      bestBuyDay: data['best_buy_day'] ?? '',
      closingPrice: (data['closing_price'] ?? 0).toDouble(),
      daysWithData: data['days_with_data'] ?? 0,
      maxPrice: (data['max_price'] ?? 0).toDouble(),
      minPrice: (data['min_price'] ?? 0).toDouble(),
      openingPrice: (data['opening_price'] ?? 0).toDouble(),
      priceRange: (data['price_range'] ?? 0).toDouble(),
      priceStabilityScore: (data['price_stability_score'] ?? 0).toDouble(),
      priceVolatility: (data['price_volatility'] ?? 0).toDouble(),
      totalChangePercent: (data['total_change_percent'] ?? 0).toDouble(),
      trendDirection: data['trend_direction'] ?? 'stable',
    );
  }
}

class MonthlyPriceHistory {
  final String id;
  final String productId;
  final String supermarketId;
  final int year;
  final int month;
  final Map<String, double> dailyPrices;
  final MonthSummary monthSummary;
  final String lastUpdated;

  MonthlyPriceHistory({
    required this.id,
    required this.productId,
    required this.supermarketId,
    required this.year,
    required this.month,
    required this.dailyPrices,
    required this.monthSummary,
    required this.lastUpdated,
  });

  factory MonthlyPriceHistory.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    final dailyPricesData = data['daily_prices'] as Map<String, dynamic>? ?? {};
    final dailyPrices = <String, double>{};

    for (final entry in dailyPricesData.entries) {
      dailyPrices[entry.key] = (entry.value ?? 0).toDouble();
    }

    return MonthlyPriceHistory(
      id: id,
      productId: data['productId'] ?? '',
      supermarketId: data['supermarketId'] ?? '',
      year: data['year'] ?? 0,
      month: data['month'] ?? 0,
      dailyPrices: dailyPrices,
      monthSummary: MonthSummary.fromFirestore(
        data['month_summary'] as Map<String, dynamic>? ?? {},
      ),
      lastUpdated: data['last_updated'] ?? '',
    );
  }

  String get monthName {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month > 0 && month < months.length) ? months[month] : '';
  }

  DateTime get monthDateTime => DateTime(year, month);
}

class PriceHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get price history for a product across multiple months
  static Future<List<MonthlyPriceHistory>> getPriceHistory(
    String supermarketId,
    String productId, {
    int monthsBack = 6,
  }) async {
    final currentDate = DateTime.now();
    final documents = <MonthlyPriceHistory>[];

    for (int i = 0; i < monthsBack; i++) {
      final targetDate = DateTime(currentDate.year, currentDate.month - i, 1);
      final year = targetDate.year;
      final month = targetDate.month.toString().padLeft(2, '0');

      final docId = '${supermarketId}_${productId}_${year}_$month';

      try {
        final docSnapshot = await _firestore
            .collection('price_history_monthly')
            .doc(docId)
            .get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          documents.add(
            MonthlyPriceHistory.fromFirestore(
              docSnapshot.data()!,
              docSnapshot.id,
            ),
          );
        }
      } catch (e) {
        AppLogger.e('Error fetching price history for $docId', error: e);
      }
    }

    // Sort by year and month (oldest first)
    documents.sort((a, b) {
      final yearCompare = a.year.compareTo(b.year);
      return yearCompare != 0 ? yearCompare : a.month.compareTo(b.month);
    });

    return documents;
  }

  /// Get current month price history
  static Future<MonthlyPriceHistory?> getCurrentMonthHistory(
    String supermarketId,
    String productId,
  ) async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');

    final docId = '${supermarketId}_${productId}_${year}_$month';

    try {
      final docSnapshot = await _firestore
          .collection('price_history_monthly')
          .doc(docId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return MonthlyPriceHistory.fromFirestore(
          docSnapshot.data()!,
          docSnapshot.id,
        );
      }
    } catch (e) {
      AppLogger.e('Error fetching current month history', error: e);
    }

    return null;
  }

  /// Get price trends across all stores for a product
  static Future<Map<String, List<MonthlyPriceHistory>>> getPriceTrendsAllStores(
    String productId, {
    int monthsBack = 3,
  }) async {
    final stores = ['cargills', 'keells', 'arpico'];
    final trends = <String, List<MonthlyPriceHistory>>{};

    for (final store in stores) {
      trends[store] = await getPriceHistory(
        store,
        productId,
        monthsBack: monthsBack,
      );
    }

    return trends;
  }

  /// Calculate price statistics across all available history
  static Map<String, dynamic> calculatePriceStatistics(
    List<MonthlyPriceHistory> history,
  ) {
    if (history.isEmpty) {
      return {
        'averagePrice': 0.0,
        'lowestPrice': 0.0,
        'highestPrice': 0.0,
        'priceVolatility': 0.0,
        'trendDirection': 'stable',
        'bestMonth': '',
        'worstMonth': '',
      };
    }

    final allPrices = <double>[];
    final monthlyAverages = <MonthlyPriceHistory>[];

    for (final month in history) {
      allPrices.addAll(month.dailyPrices.values);
      monthlyAverages.add(month);
    }

    allPrices.sort();
    final averagePrice = allPrices.reduce((a, b) => a + b) / allPrices.length;
    final lowestPrice = allPrices.first;
    final highestPrice = allPrices.last;

    // Calculate volatility
    final variance =
        allPrices
            .map((price) => (price - averagePrice) * (price - averagePrice))
            .reduce((a, b) => a + b) /
        allPrices.length;
    final volatility = (variance.isNaN ? 0.0 : variance) / averagePrice * 100;

    // Find best and worst months
    monthlyAverages.sort(
      (a, b) => a.monthSummary.avgPrice.compareTo(b.monthSummary.avgPrice),
    );
    final bestMonth = monthlyAverages.isNotEmpty ? monthlyAverages.first : null;
    final worstMonth = monthlyAverages.isNotEmpty ? monthlyAverages.last : null;

    // Calculate trend
    String trendDirection = 'stable';
    if (history.length >= 2) {
      final firstMonth = history.first.monthSummary.avgPrice;
      final lastMonth = history.last.monthSummary.avgPrice;
      final changePercent = ((lastMonth - firstMonth) / firstMonth) * 100;

      if (changePercent > 5) {
        trendDirection = 'upward';
      } else if (changePercent < -5) {
        trendDirection = 'downward';
      }
    }

    return {
      'averagePrice': averagePrice,
      'lowestPrice': lowestPrice,
      'highestPrice': highestPrice,
      'priceVolatility': volatility,
      'trendDirection': trendDirection,
      'bestMonth': bestMonth?.monthName ?? '',
      'worstMonth': worstMonth?.monthName ?? '',
      'totalDataPoints': allPrices.length,
    };
  }
}
