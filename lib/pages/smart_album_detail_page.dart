import 'dart:developer';
import 'dart:io';

import 'package:flutter_yuuna_album/models/Photo.dart';
import 'package:flutter_yuuna_album/services/classifier_vgg16.dart';
import 'package:flutter_yuuna_album/services/photos_service.dart';
import 'package:flutter_yuuna_album/utils/image_util.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_yuuna_album/services/classifier.dart';
import 'package:logger/logger.dart';

/// 智能相册类别列表详情界面
class SmartAlbumDetailPage extends StatefulWidget {
  final String category;
  final String categoryTitle;

  const SmartAlbumDetailPage({Key? key, required this.category, required this.categoryTitle})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SmartAlbumDetailState();
}

class _SmartAlbumDetailState extends State<SmartAlbumDetailPage> {
  var logger = Logger();

  final List<File> _images = [];

  late Classifier _classifier;

  @override
  void initState() {
    super.initState();
    _classifier = ClassifierVGG16();
    _initAsync();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initAsync() async {
    _updateNotHaveCategories();
    _getImages();
  }

  /// 使未完成分类的图片更新分类
  void _updateNotHaveCategories() async {
    PhotosService dbHelper = PhotosService();
    List<Photo> photoList = await dbHelper.getAnyNotCategoryPhotos();
    if (photoList.isNotEmpty) {
      // 初始化图像分类模型
      for (var photo in photoList) {
        // 封装图片文件
        File imageFile = File(photo.imagePath);
        img.Image imageInput = img.decodeImage(imageFile.readAsBytesSync())!;
        // 获取分类结果并更新数据库
        try {
          var predict = _classifier.predict(imageInput);
          log('[${photo.imagePath}] predict result is [${predict.label}], and the confidence score is [${predict.score}]');

          if (predict.score > 0.5) {
            photo.tags = '${predict.label},';
          }
          photo.status = 101;
          int count = await dbHelper.updatePhoto(photo);
          log('update photo count is $count');
        } catch (e, stacktrace) {
          logger.e("Exception: $e");
          logger.e("Stacktrace: $stacktrace");
        }
      }
      _classifier.close();
    }
  }

  /// 从sqlite数据库中加载图片
  void _getImages() async {
    PhotosService dbHelper = PhotosService();
    for (final photo in await dbHelper.getSmartCategoryAlbumPhotos(widget.category)) {
      // log(photo.imagePath);
      _images.add(File(photo.imagePath));
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用FutureBuilder构建图片异步加载器组件
    return FutureBuilder<Map<String, List<File>>>(
        future: groupImagesByDate(_images),
        builder: (BuildContext context, AsyncSnapshot<Map<String, List<File>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            Map<String, List<File>> groupedImages = snapshot.data!;

            if (groupedImages.isNotEmpty) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(widget.categoryTitle),
                ),
                body: ListView.builder(
                  itemCount: groupedImages.length,
                  itemBuilder: (BuildContext context, int index) {
                    String date = groupedImages.keys.elementAt(index);
                    List<File> images = groupedImages[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.grey[100],
                          child: Text(
                            date,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            crossAxisCount: 4,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: images.length,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            return _buildImageTile(images[index]);
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator()); // 在没有图片时显示一个提示
            }
          } else {
            return const Center(child: CircularProgressIndicator()); // 显示一个加载指示器
          }
        });
  }

  /// 图片渲染组件
  Widget _buildImageTile(File imageFile) {
    return FutureBuilder<Size>(
      future: getImageSize(imageFile),
      builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.file(
            imageFile,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } else {
          return Container(); // 如果无法获取图片尺寸，则返回一个空容器
        }
      },
    );
  }
}
