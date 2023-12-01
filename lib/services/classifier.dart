import 'dart:math';
import 'dart:developer' as developer;

import 'package:image/image.dart';
import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

/// 图片分类器抽象类
abstract class Classifier {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;

  var logger = Logger();

  late List<int> _inputShape;
  late List<int> _outputShape;

  late TensorImage _inputImage;
  late TensorBuffer _outputBuffer;

  late TfLiteType _inputType;
  late TfLiteType _outputType;

  final String _labelsFileName = 'assets/tflite/classification_labels.txt';

  final int _labelsLength = 5;

  late var _probabilityProcessor;

  late List<String> labels;

  String get modelName;

  NormalizeOp get preProcessNormalizeOp;
  NormalizeOp get postProcessNormalizeOp;

  Classifier({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }

    loadModel();
    loadLabels();
  }

  /// 模型加载方法
  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(modelName, options: _interpreterOptions);
      developer.log('Interpreter Created Successfully');

      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;
      _inputType = interpreter.getInputTensor(0).type;
      _outputType = interpreter.getOutputTensor(0).type;

      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
      _probabilityProcessor = TensorProcessorBuilder().add(postProcessNormalizeOp).build();
    } catch (e) {
      logger.e('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  /// 加载分类标签
  Future<void> loadLabels() async {
    labels = await FileUtil.loadLabels(_labelsFileName);
    if (labels.length == _labelsLength) {
      developer.log('Labels loaded successfully');
    } else {
      logger.e('Unable to load labels');
    }
  }

  /// 预处理图片
  TensorImage _preProcess() {
    int cropSize = min(_inputImage.height, _inputImage.width);
    return ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(_inputShape[1], _inputShape[2], ResizeMethod.NEAREST_NEIGHBOUR)) // resize to 224x224
        .add(preProcessNormalizeOp)
        .build()
        .process(_inputImage);
  }

  /// 图像类别预测
  Category predict(Image image) {
    final pres = DateTime.now().millisecondsSinceEpoch;
    _inputImage = TensorImage(_inputType); // inputType为float32
    _inputImage.loadImage(image);
    _inputImage = _preProcess();
    _inputImage.getTensorBuffer().resize([1, 224, 224, 3]); // [1, 224, 224, 3]
    final pre = DateTime.now().millisecondsSinceEpoch - pres;

    developer.log('Time to load image: $pre ms');

    final runs = DateTime.now().millisecondsSinceEpoch;
    interpreter.run(_inputImage.getBuffer(), _outputBuffer.getBuffer());
    final run = DateTime.now().millisecondsSinceEpoch - runs;

    developer.log('Time to run inference: $run ms');

    Map<String, double> labeledProb = TensorLabel.fromList(
        labels, _probabilityProcessor.process(_outputBuffer))
        .getMapWithFloatValue();
    final pred = getTopProbability(labeledProb);

    return Category(pred.key, pred.value);
  }

  /// 释放解释器资源
  void close() {
    interpreter.close();
  }
}

/// 获取最大概率的标签
MapEntry<String, double> getTopProbability(Map<String, double> labeledProb) {
  var pq = PriorityQueue<MapEntry<String, double>>(compare);
  pq.addAll(labeledProb.entries);

  return pq.first;
}

/// 用于 PriorityQueue 的比较函数
int compare(MapEntry<String, double> e1, MapEntry<String, double> e2) {
  if (e1.value > e2.value) {
    return -1;
  } else if (e1.value == e2.value) {
    return 0;
  } else {
    return 1;
  }
}