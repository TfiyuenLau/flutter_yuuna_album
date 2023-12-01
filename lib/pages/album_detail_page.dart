import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/photos_service.dart';
import '../utils/image_util.dart';

/// 相册列表详情界面
class AlbumDetailPage extends StatefulWidget {
  final String albumTitle;

  const AlbumDetailPage({Key? key, required this.albumTitle}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AlbumDetailState();
}

class _AlbumDetailState extends State<AlbumDetailPage> {
  final List<File> _images = [];

  /// 从sqlite数据库中加载图片
  void _getImages() async {
    PhotosService dbHelper = PhotosService();
    for (final photo in await dbHelper.getAlbumPhotos(widget.albumTitle)) {
      // log(photo.imagePath);
      _images.add(File(photo.imagePath));
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _getImages();
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
                  title: Text(widget.albumTitle),
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
              return const Center(child: Text('No images found')); // 在没有图片时显示一个提示
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
