import 'dart:io';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../utils/app_logger.dart';

class TeachableMachineService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;

  // Singleton pattern
  static final TeachableMachineService _instance =
      TeachableMachineService._internal();
  factory TeachableMachineService() => _instance;
  TeachableMachineService._internal();

  bool get isModelLoaded => _isModelLoaded;

  /// Loads the model from Firebase ML and labels from assets.
  Future<void> loadFromFirebase({required String modelName}) async {
    try {
      // Download model from Firebase ML
      final model = await FirebaseModelDownloader.instance.getModel(
        modelName,
        FirebaseModelDownloadType.localModel,
        FirebaseModelDownloadConditions(),
      );

      // Load labels from assets
      final labelsContent = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsContent
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      // Load Interpreter from the downloaded model file
      _interpreter = Interpreter.fromFile(model.file);

      _isModelLoaded = true;
      AppLogger.d(
        'Model loaded successfully from Firebase ML. Labels: $_labels',
      );
    } catch (e) {
      AppLogger.e('Error loading model from Firebase: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  /// Loads the model and labels from the given URLs (Legacy/Direct URL method).
  /// If [modelUrl] and [labelsUrl] are provided, it downloads them.
  Future<void> loadModel({
    required String modelUrl,
    required String labelsUrl,
  }) async {
    try {
      await _downloadAndLoadModel(modelUrl, labelsUrl);
    } catch (e) {
      AppLogger.e('Error loading model: $e');
      _isModelLoaded = false;
    }
  }

  Future<void> _downloadAndLoadModel(String modelUrl, String labelsUrl) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/model.tflite');
    final labelsFile = File('${appDir.path}/labels.txt');

    // Download latest model; consider version caching for production
    try {
      AppLogger.d('Downloading model from $modelUrl...');
      final modelResponse = await http.get(Uri.parse(modelUrl));
      if (modelResponse.statusCode == 200) {
        await modelFile.writeAsBytes(modelResponse.bodyBytes);
      } else {
        AppLogger.e('Failed to download model: ${modelResponse.statusCode}');
        // If download fails, try to use existing file if available
        if (!await modelFile.exists()) {
          throw Exception('Failed to download model and no local cache');
        }
      }

      AppLogger.d('Downloading labels from $labelsUrl...');
      final labelsResponse = await http.get(Uri.parse(labelsUrl));
      if (labelsResponse.statusCode == 200) {
        await labelsFile.writeAsString(labelsResponse.body);
      } else {
        AppLogger.e('Failed to download labels: ${labelsResponse.statusCode}');
        if (!await labelsFile.exists()) {
          throw Exception('Failed to download labels and no local cache');
        }
      }

      // Load Interpreter
      _interpreter = Interpreter.fromFile(modelFile);

      // Load Labels
      final labelsContent = await labelsFile.readAsString();
      _labels = labelsContent
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      _isModelLoaded = true;
      AppLogger.d('Model loaded successfully. Labels: $_labels');
    } catch (e) {
      AppLogger.e('Error in _downloadAndLoadModel: $e');
      rethrow;
    }
  }

  Future<String?> classifyImage(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null || _labels == null) {
      AppLogger.w('Model not loaded. Call loadModel() first.');
      return null;
    }

    try {
      // 1. Preprocess image
      final imageData = await imageFile.readAsBytes();
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      // Resize to 224x224 (standard for Teachable Machine)
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to input tensor [1, 224, 224, 3]
      // Teachable Machine standard export is usually normalized to [-1, 1]
      // (pixel - 127.5) / 127.5
      final input = _imageTo4DList(resizedImage, 224, 127.5, 127.5);

      // Allocate output tensor [1, num_classes]
      final output = List.filled(
        1 * _labels!.length,
        0.0,
      ).reshape([1, _labels!.length]);

      // Run inference
      _interpreter!.run(input, output);

      // Get result
      final result = output[0] as List<double>;

      // Find max confidence
      double maxScore = -1;
      int maxIndex = -1;

      for (int i = 0; i < result.length; i++) {
        if (result[i] > maxScore) {
          maxScore = result[i];
          maxIndex = i;
        }
      }

      // Confidence threshold (e.g., 70%)
      if (maxIndex != -1 && maxScore > 0.7) {
        return _labels![maxIndex].trim();
      }

      return null;
    } catch (e) {
      AppLogger.e('Error classifying image: $e');
      return null;
    }
  }

  List<List<List<List<double>>>> _imageTo4DList(
    img.Image image,
    int inputSize,
    double mean,
    double std,
  ) {
    var imageList = List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            (pixel.r - mean) / std,
            (pixel.g - mean) / std,
            (pixel.b - mean) / std,
          ];
        }),
      ),
    );
    return imageList;
  }

  void dispose() {
    _interpreter?.close();
  }
}

extension ReshapeExtension on List<double> {
  List<dynamic> reshape(List<int> shape) {
    var flat = this;
    if (shape.length == 2) {
      int rows = shape[0];
      int cols = shape[1];
      return List.generate(rows, (i) => flat.sublist(i * cols, (i + 1) * cols));
    }
    return this; // 2D reshape only
  }
}
