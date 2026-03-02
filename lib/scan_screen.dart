import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Interpreter? interpreter;
  File? imageFile;
  String result = "No scan yet";
  bool isPredicting = false;

  static const List<String> _defaultLabels = [
    'Cardboard',
    'Glass',
    'Paper',
    'Plastic',
  ];

  List<String> labels = List<String>.from(_defaultLabels);

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/model.tflite');

    await _loadLabels();

    if (!mounted) return;
    setState(() {
      result = 'Model loaded. Open camera to scan.';
    });
  }

  Future<void> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString('assets/labels.txt');
      final loaded = raw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (loaded.isNotEmpty) {
        labels = loaded;
      }
    } catch (_) {
      labels = List<String>.from(_defaultLabels);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
        result = 'Scanned. Running model...';
      });

      await runInference(File(pickedFile.path));
    }
  }

  Future<void> runInference(File file) async {
    if (interpreter == null) {
      setState(() {
        result = 'Model not loaded';
      });
      return;
    }

    setState(() {
      isPredicting = true;
    });

    try {
      final imageBytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        setState(() {
          result = 'Could not decode image';
          isPredicting = false;
        });
        return;
      }

      final inputTensor = interpreter!.getInputTensor(0);
      final outputTensor = interpreter!.getOutputTensor(0);

      final inputShape = inputTensor.shape;
      final inputType = inputTensor.type;
      final outputType = outputTensor.type;
      final inputScale = inputTensor.params.scale;
      final inputZeroPoint = inputTensor.params.zeroPoint;
      final outputScale = outputTensor.params.scale;
      final outputZeroPoint = outputTensor.params.zeroPoint;

      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];
      final inputChannels = inputShape[3];

      final oriented = img.bakeOrientation(decodedImage);

      final resized = img.copyResize(
        oriented,
        width: inputWidth,
        height: inputHeight,
      );

      Object input;

      if (inputType == TensorType.float32) {
        input = [
          List.generate(inputHeight, (y) {
            return List.generate(inputWidth, (x) {
              final pixel = resized.getPixel(x, y);
              final red = pixel.r / 255.0;
              final green = pixel.g / 255.0;
              final blue = pixel.b / 255.0;

              if (inputChannels == 1) {
                final gray = (red + green + blue) / 3.0;
                return [gray];
              }

              return [red, green, blue];
            });
          }),
        ];
      } else if (inputType == TensorType.uint8 ||
          inputType == TensorType.int8) {
        input = [
          List.generate(inputHeight, (y) {
            return List.generate(inputWidth, (x) {
              final pixel = resized.getPixel(x, y);
              final red = pixel.r / 255.0;
              final green = pixel.g / 255.0;
              final blue = pixel.b / 255.0;

              int quantize(double value01) {
                if (inputScale == 0) {
                  if (inputType == TensorType.int8) {
                    return ((value01 * 255.0).round() - 128).clamp(-128, 127);
                  }
                  return (value01 * 255.0).round().clamp(0, 255);
                }

                final q = (value01 / inputScale + inputZeroPoint).round();
                if (inputType == TensorType.int8) {
                  return q.clamp(-128, 127);
                }
                return q.clamp(0, 255);
              }

              if (inputChannels == 1) {
                final gray = (red + green + blue) / 3.0;
                return [quantize(gray)];
              }

              return [quantize(red), quantize(green), quantize(blue)];
            });
          }),
        ];
      } else {
        input = [
          List.generate(inputHeight, (y) {
            return List.generate(inputWidth, (x) {
              final pixel = resized.getPixel(x, y);
              final red = pixel.r.toInt();
              final green = pixel.g.toInt();
              final blue = pixel.b.toInt();

              if (inputChannels == 1) {
                final gray = ((red + green + blue) / 3).round();
                return [gray];
              }

              return [red, green, blue];
            });
          }),
        ];
      }

      final classCount = outputTensor.shape.last;

      if (outputType == TensorType.float32) {
        final output = [List<double>.filled(classCount, 0.0)];
        interpreter!.run(input, output);
        _renderResult(output[0]);
      } else {
        final output = [List<int>.filled(classCount, 0)];
        interpreter!.run(input, output);
        final dequantized = output[0].map((score) {
          if (outputScale == 0) {
            return score.toDouble();
          }
          return (score - outputZeroPoint) * outputScale;
        }).toList();
        _renderResult(dequantized);
      }
    } catch (_) {
      setState(() {
        result = 'Inference failed. Check model input/output format.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isPredicting = false;
        });
      }
    }
  }

  void _renderResult(List<double> scores) {
    final probs = _toProbabilities(scores);
    final maxScore = probs.reduce((a, b) => a > b ? a : b);
    final topIndex = probs.indexOf(maxScore);

    final topLabel = topIndex < labels.length
        ? labels[topIndex]
        : 'Class $topIndex';

    final lines = <String>[];
    for (int i = 0; i < probs.length && i < labels.length; i++) {
      lines.add('${labels[i]}: ${(probs[i] * 100).toStringAsFixed(1)}%');
    }

    setState(() {
      result =
          'Top: $topLabel (${(maxScore * 100).toStringAsFixed(1)}%)\n\n${lines.join('\n')}';
    });
  }

  List<double> _toProbabilities(List<double> rawScores) {
    if (rawScores.isEmpty) {
      return rawScores;
    }

    final alreadyProbabilities = rawScores.every((s) => s >= 0 && s <= 1);
    final sum = rawScores.fold<double>(0, (a, b) => a + b);

    if (alreadyProbabilities && sum > 0.9 && sum < 1.1) {
      return rawScores;
    }

    final maxLogit = rawScores.reduce((a, b) => a > b ? a : b);
    final expScores = rawScores.map((s) => math.exp(s - maxLogit)).toList();
    final expSum = expScores.fold<double>(0, (a, b) => a + b);

    if (expSum == 0) {
      return List<double>.filled(rawScores.length, 0);
    }

    return expScores.map((v) => v / expSum).toList();
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan Waste")),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageFile != null) Image.file(imageFile!, height: 250),

          SizedBox(height: 20),

          Text(
            result,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),

          if (isPredicting) ...[
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],

          SizedBox(height: 20),

          ElevatedButton(onPressed: pickImage, child: Text("Open Camera")),
        ],
      ),
    );
  }
}
