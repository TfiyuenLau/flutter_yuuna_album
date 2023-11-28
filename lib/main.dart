import 'package:flutter/material.dart';
import 'common/app_theme.dart';
import 'pages/recent_photos_page.dart';
import 'pages/albums_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const YuunaAlbumApp());
}

/// Material3 Application
class YuunaAlbumApp extends StatelessWidget {
  const YuunaAlbumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yuuna Album',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppHomePage(),
    );
  }
}

/// A stateful home page,include bottom navigation bar.
class AppHomePage extends StatefulWidget {
  const AppHomePage({super.key});

  @override
  AppHomePageState createState() => AppHomePageState();
}

class AppHomePageState extends State<AppHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    RecentPhotosPage(),
    AlbumsPage(),
    ImageClassificationPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: '最近照片',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: '全部相册',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '通用设置',
          ),
        ],
      ),
    );
  }
}
