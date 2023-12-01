import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_yuuna_album/pages/album_detail_page.dart';
import 'package:flutter_yuuna_album/pages/smart_album_detail_page.dart';

import '../services/photos_service.dart';

/// 全部相册界面
class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<StatefulWidget> createState() => AlbumsPageState();
}

class AlbumsPageState extends State<AlbumsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全部相册'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          iconSize: 32,
          color: Colors.black54,
          tooltip: "工具栏",
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 系统相册
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '系统相册',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildAlbumCategory(
                  context,
                  title: 'Camera',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AlbumDetailPage(albumTitle: 'Camera')),
                    );
                  },
                ),
              ],
            ),
            // 应用相册
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '应用相册',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildAppAlbumCategoryList(context),
              ],
            ),
            // 智能相册
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '智能相册',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildSmartAlbumCategoryList(),
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
              future: getAlbumFirstPhotoPath(title), // 异步获取相册的第一张图片路径
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
  Widget _buildAppAlbumCategoryList(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getAppAlbumPathNames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final List<String> appAlbumTitles = snapshot.data!;

          // 使用 GridView.builder 来生成应用相册
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 每行显示 3 个应用相册
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: appAlbumTitles.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final appAlbumTitle = appAlbumTitles[index];
              return _buildAlbumCategory(
                context,
                title: appAlbumTitle,
                onTap: () => _navigateToAppAlbumPage(context, appAlbumTitle),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  /// 智能相册类别组件
  Widget _buildSmartAlbumCategoryList() {
    final List<Map<String, dynamic>> smartAlbumCategories = [
      {'category': 'animal', 'title': '动物', 'icon': Icons.pets},
      {'category': 'anime', 'title': '插画', 'icon': Icons.draw_rounded},
      {'category': 'human', 'title': '人物', 'icon': Icons.person},
      {'category': 'landscape', 'title': '风景', 'icon': Icons.landscape},
      {'category': 'plant', 'title': '植物', 'icon': Icons.park_rounded},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: smartAlbumCategories.length,
      itemBuilder: (context, index) {
        final category = smartAlbumCategories[index];
        return ListTile(
          leading: Icon(category['icon'] as IconData),
          title: Text(category['title'] as String),
          onTap: () => _navigateToSmartAlbumPage(context, category['category'] as String, category['title'] as String),
        );
      },
    );
  }

  Future<String> getAlbumFirstPhotoPath(String like) async {
    PhotosService dbHelper = PhotosService();
    return dbHelper.getAlbumFirstPhotoPath(like);
  }

  Future<List<String>> getAppAlbumPathNames() async {
    PhotosService dbHelper = PhotosService();
    return dbHelper.getAppAlbumPathNames();
  }

  void _navigateToAppAlbumPage(BuildContext context, String albumTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(builder:
          (context) => AlbumDetailPage(albumTitle: albumTitle)
      ),
    );
  }

  void _navigateToSmartAlbumPage(BuildContext context, String category, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder:
          (context) => SmartAlbumDetailPage(category: category, categoryTitle: categoryName)
      ),
    );
  }
}
