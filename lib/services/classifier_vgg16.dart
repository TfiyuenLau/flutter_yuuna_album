import 'package:flutter_yuuna_album/services/classifier.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

/// VGG16图像分类器实现类
class ClassifierVGG16 extends Classifier {
  ClassifierVGG16({int? numThreads}) : super(numThreads: numThreads);

  @override
  String get modelName => 'tflite/yuuna_album_vgg16.tflite'; // assets下的模型文件

  @override
  NormalizeOp get preProcessNormalizeOp => NormalizeOp(0, 255.0); // 归一化[0, 1]

  @override
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 1);
}
