import 'package:flutter/material.dart';

class ImageClassificationPage extends StatelessWidget {
  const ImageClassificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          iconSize: 32,
          color: Colors.black54,
          tooltip: "工具栏",
          onPressed: () {},
        ),
      ),
      body: const Center(
        child: Text('这里是相册全局通用设置页面'),
      ),
    );
  }
}
