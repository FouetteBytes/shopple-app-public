import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void setupFakeAssetManifest(
  TestWidgetsFlutterBinding binding,
  ByteData fontData,
) {
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    message,
  ) async {
    if (message == null) return null;
    final key = utf8.decode(message.buffer.asUint8List());

    if (key == 'AssetManifest.json') {
      // Create a fake manifest with Lato fonts
      final manifest = {
        'google_fonts/Lato-Regular.ttf': ['google_fonts/Lato-Regular.ttf'],
        'google_fonts/Lato-Bold.ttf': ['google_fonts/Lato-Bold.ttf'],
        'google_fonts/Lato-Italic.ttf': ['google_fonts/Lato-Italic.ttf'],
        'google_fonts/Lato-BoldItalic.ttf': [
          'google_fonts/Lato-BoldItalic.ttf',
        ],
      };
      return ByteData.view(
        Uint8List.fromList(utf8.encode(json.encode(manifest))).buffer,
      );
    }

    if (key == 'AssetManifest.bin') {
      final manifest = {
        'google_fonts/Lato-Regular.ttf': ['google_fonts/Lato-Regular.ttf'],
        'google_fonts/Lato-Bold.ttf': ['google_fonts/Lato-Bold.ttf'],
        'google_fonts/Lato-Italic.ttf': ['google_fonts/Lato-Italic.ttf'],
        'google_fonts/Lato-BoldItalic.ttf': [
          'google_fonts/Lato-BoldItalic.ttf',
        ],
      };
      return const StandardMessageCodec().encodeMessage(manifest);
    }

    if (key.contains('Lato')) {
      return fontData;
    }

    // For other assets, try to read from filesystem
    // In tests, assets are usually relative to project root
    final file = File(key);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    }

    if (key.endsWith('.svg')) {
      // Return dummy SVG
      final svg = '<svg viewBox="0 0 1 1"></svg>';
      return ByteData.view(Uint8List.fromList(utf8.encode(svg)).buffer);
    }

    return null;
  });
}

class FakeAssetBundle extends Fake implements AssetBundle {
  final AssetBundle _parent;
  final ByteData fontData;

  FakeAssetBundle(this._parent, this.fontData);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = {
        'google_fonts/Lato-Regular.ttf': ['google_fonts/Lato-Regular.ttf'],
        'google_fonts/Lato-Bold.ttf': ['google_fonts/Lato-Bold.ttf'],
        'google_fonts/Lato-Italic.ttf': ['google_fonts/Lato-Italic.ttf'],
        'google_fonts/Lato-BoldItalic.ttf': [
          'google_fonts/Lato-BoldItalic.ttf',
        ],
      };
      return const StandardMessageCodec().encodeMessage(manifest)!;
    }
    if (key.contains('Lato')) {
      return fontData;
    }
    return _parent.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _parent.loadString(key, cache: cache);
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async {
    if (key == 'AssetManifest.json') {
      try {
        final manifestContent = await _parent.loadString(key);
        final Map<String, dynamic> manifest = json.decode(manifestContent);

        // Add fake Lato fonts
        manifest['google_fonts/Lato-Regular.ttf'] = [
          'google_fonts/Lato-Regular.ttf',
        ];
        manifest['google_fonts/Lato-Bold.ttf'] = ['google_fonts/Lato-Bold.ttf'];
        manifest['google_fonts/Lato-Italic.ttf'] = [
          'google_fonts/Lato-Italic.ttf',
        ];
        manifest['google_fonts/Lato-BoldItalic.ttf'] = [
          'google_fonts/Lato-BoldItalic.ttf',
        ];

        return parser(json.encode(manifest));
      } catch (e) {
        // If parent fails to load manifest (e.g. it doesn't exist), create a new one
        final manifest = {
          'google_fonts/Lato-Regular.ttf': ['google_fonts/Lato-Regular.ttf'],
          'google_fonts/Lato-Bold.ttf': ['google_fonts/Lato-Bold.ttf'],
          'google_fonts/Lato-Italic.ttf': ['google_fonts/Lato-Italic.ttf'],
          'google_fonts/Lato-BoldItalic.ttf': [
            'google_fonts/Lato-BoldItalic.ttf',
          ],
        };
        return parser(json.encode(manifest));
      }
    }
    return _parent.loadStructuredData(key, parser);
  }
}
