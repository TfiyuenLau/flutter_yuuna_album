# flutter_yuuna_album

## Ⅰ、Introduction

>近期暂无UI优化与iOS跨端计划。

一个使用Flutter开发的Material Design风格智能相册APP。

- **照片展示：** 展示系统相册、应用相册，并根据时间和位置信息智能分类相片。
- **图像分类：** 基于VGG16预训练模型，使用 TensorFlow Lite 进行图像分类。
- **人脸聚类：** 利用GCN人脸聚类技术对照片进行聚类，方便用户查找相片。

## Ⅱ、Getting Started

1. 环境配置： 请确保你的开发环境已正确配置 Flutter，并且下载了tflite图像分类模型。
2. 获取依赖： 在项目根目录运行 flutter pub get 来获取所有依赖。
3. 运行应用： 使用 flutter run 命令来启动应用程序。
