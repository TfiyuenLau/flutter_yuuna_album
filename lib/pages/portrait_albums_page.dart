import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_yuuna_album/pages/smart_album_detail_page.dart';

import '../services/photos_service.dart';

/// 全部相册界面
class PortraitAlbumsPage extends StatefulWidget {
  const PortraitAlbumsPage({super.key});

  @override
  State<StatefulWidget> createState() => PortraitAlbumsPageState();
}

class PortraitAlbumsPageState extends State<PortraitAlbumsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人物'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 应用相册
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPortraitAlbumCategoryGird(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 单个相册类别组件
  Widget _buildAlbumCategory(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            FutureBuilder<String>(
              future: getPortraitAlbumFirstPhotoPath(title), // 异步获取相册的第一张图片路径
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(snapshot.data!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  // 如果无法获取图片，则显示一个占位图标
                  return const Icon(Icons.photo, size: 100, color: Colors.grey);
                }
              },
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  /// 应用相册类别组件列表
  Widget _buildPortraitAlbumCategoryGird(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getHumanCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final List<String> portraitList = snapshot.data!;

          // 使用 GridView.builder 来生成应用相册
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 每行显示 3 个应用相册
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: portraitList.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final portraitName = portraitList[index];
              return _buildAlbumCategory(
                context,
                title: portraitName,
                onTap: () => _navigateToSmartAlbumPage(context, portraitName, portraitName),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<String> getPortraitAlbumFirstPhotoPath(String like) async {
    PhotosService dbHelper = PhotosService();
    return dbHelper.getPortraitAlbumFirstPhotoPath(like);
  }

  Future<List<String>> getHumanCategories() async {
    PhotosService dbHelper = PhotosService();
    return dbHelper.getHumanCategories();
  }

  void _navigateToSmartAlbumPage(BuildContext context, String category, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SmartAlbumDetailPage(category: category, categoryTitle: categoryName)),
    );
  }
}
