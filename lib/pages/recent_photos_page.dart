import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/photos_service.dart';
import '../utils/image_util.dart';

/// 最近照片页面
class RecentPhotosPage extends StatefulWidget {
  const RecentPhotosPage({super.key});

  @override
  RecentPhotosPageState createState() => RecentPhotosPageState();
}

class RecentPhotosPageState extends State<RecentPhotosPage> {
  int _columnCount = 4; // 栅格列数
  final List<File> _images = [];

  @override
  void initState() {
    super.initState();
    setPermission();
    _checkDbPhotosInitialization();
  }

  /// 申请访问外部存储权限
  Future<bool> setPermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    } else {
      throw Exception("OS Error: Permission denied, errno = 13");
    }
  }

  /// 检查若为初次启动则初始化photos表
  void _checkDbPhotosInitialization() async {
    PhotosService dbHelper = PhotosService();
    bool isInitialized = await dbHelper.isPhotosInit();

    if (!isInitialized) {
      loadPhotosInsertDB(); // 如果未初始化表，调用加载并插入数据库的方法
      log("Init successfully.");
    }

    _showPhotos();
  }

  /// 从sqlite数据库中加载图片
  void _showPhotos() async {
    PhotosService dbHelper = PhotosService();
    for (final photo in await dbHelper.getRecentPhotos(64)) {
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
                appBar: _RecentPhotosBar(
                  onGridItemCountChanged: _toggleColumnCount,
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
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            crossAxisCount: _columnCount,
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

  /// 切换列数
  void _toggleColumnCount() {
    setState(() {
      _columnCount = (_columnCount == 4) ? 1 : 4;
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

class _RecentPhotosBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onGridItemCountChanged;

  const _RecentPhotosBar({Key? key, required this.onGridItemCountChanged}) : super(key: key);

  @override
  _RecentPhotosBarState createState() => _RecentPhotosBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 导航栏无状态组件
class _RecentPhotosBarState extends State<_RecentPhotosBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("最近照片"),
      leading: _buildMenuButton(),
      actions: [_buildSettingButton()],
    );
  }

  Widget _buildMenuButton() {
    return IconButton(
      icon: const Icon(Icons.menu),
      iconSize: 32,
      color: Colors.black54,
      tooltip: "工具栏",
      onPressed: () {},
    );
  }

  Widget _buildSettingButton() {
    return IconButton(
      icon: const Icon(Icons.apps_outlined),
      iconSize: 32,
      color: Colors.indigo,
      tooltip: "列表布局",
      onPressed: () {
        widget.onGridItemCountChanged(); // 调用回调来切换列数
      },
    );
  }
}
