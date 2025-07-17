import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart';

class TFLiteSegmenter {
  Interpreter? _interpreter;
    final int inputSize = 256;
  final int numClasses = 6;

    TFLiteSegmenter();

  Future<void> init() async {
     _interpreter = await Interpreter.fromAsset('assets/tensor/selfie_multiclass_256x256.tflite');
  }

  Future<Uint8List> runSegmentation(Uint8List imageBytes) async {
        if (_interpreter == null) {
      throw Exception('Interpreter not initialized. Call init() before using runSegmentation.');
    }
    final original = decodeImage(imageBytes)!;
    final resized = copyResize(original, width: inputSize, height: inputSize);

    // Crear input Float32 de forma manual
    var input = List.generate(1, (_) =>
      List.generate(inputSize, (y) =>
        List.generate(inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [
            p.rNormalized,
            p.gNormalized,
            p.bNormalized,
          ];
        })
      )
    );

    var output = List.generate(1, (_) =>
      List.generate(inputSize, (_) =>
        List.generate(inputSize, (_) => List.filled(numClasses, 0.0))
      )
    );

        _interpreter!.run(input, output);

    var mask = List.generate(inputSize, (y) =>
      List.generate(inputSize, (x) {
        final scores = output[0][y][x];
        double max = scores[0];
        int idx = 0;
        for (int i = 1; i < scores.length; i++) {
          if (scores[i] > max) {
            max = scores[i];
            idx = i;
          }
        }
        return idx;
      })
    );

    var transparent = Image(width: inputSize, height: inputSize, numChannels: 4);

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        if (mask[y][x] == 4) { // ropa
          final p = resized.getPixel(x, y);
          transparent.setPixelRgba(
            x, y,
            p.r,
            p.g,
            p.b,
            255,
          );
        } else {
          transparent.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    final cropped = _cropToContent(transparent);
    return Uint8List.fromList(encodePng(cropped));
  }

  Image _cropToContent(Image imgData) {
    int left = imgData.width, top = imgData.height;
    int right = 0, bottom = 0;

    for (int y = 0; y < imgData.height; y++) {
      for (int x = 0; x < imgData.width; x++) {
        if (imgData.getPixel(x, y).a > 10) {
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
    }

    if (left > right || top > bottom) {
      return Image(width: 1, height: 1, numChannels: 4);
    }

    return copyCrop(imgData, x: left, y: top, width: right - left + 1, height: bottom - top + 1);
  }
}