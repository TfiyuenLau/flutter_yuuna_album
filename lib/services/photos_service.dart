import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/Photo.dart';

/// SQLite数据库Photos操作服务类
class PhotosService {
  static final PhotosService _instance = PhotosService._internal();

  factory PhotosService() => _instance;

  static Database? _database;

  PhotosService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  /// SQLite数据库配置
  void _onConfigure(Database db) async {
    await db.execute('PRAGMA read_uncommitted = true;');
  }

  /// 指定内部储存路径并初始化数据库
  Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "yuuna_album.db");
    return await openDatabase(path, version: 1, onConfigure: _onConfigure);
  }

  /// 判断photos表是否初始化
  Future<bool> isPhotosInit() async {
    Database db = await database;
    List<Map<String, dynamic>> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
    bool isInit = tables.any((table) => table["name"] == "photos");

    if (!isInit) {
      // 初始化photos表
      _createPhotosTable(db, 1);
    } else {
      // 若photos表中没有数据则视为没有初始化
      if (await getPhotosCount() == 0) {
        isInit = false;
      }
    }

    log("photos count:${await getPhotosCount()}");
    return isInit;
  }

  /// Photo建表与索引
  void _createPhotosTable(Database db, int version) async {
    await db.execute("""
      CREATE TABLE photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT,
        imagePath TEXT,
        createTime DATETIME,
        updateTime DATETIME,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        width INTEGER,
        height INTEGER,
        fileSize REAL,
        status INTEGER,
        tags TEXT
      )
    """);
    await db.execute("""
      CREATE INDEX idx_filename ON photos (filename);
      CREATE INDEX idx_timestamp ON photos (createTime);
      CREATE INDEX idx_path ON photos (imagePath);
      CREATE INDEX idx_tags ON photos (tags);
    """);
  }

  /// 获取photos当前count
  Future<int> getPhotosCount() async {
    Database db = await database;
    List<Map<String, dynamic>> countMapList = await db.rawQuery("select count(*) from photos;");
    return countMapList.first["count(*)"];
  }

  /// 获取所有照片
  Future<List<Photo>> getAllPhotos() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      "photos",
      orderBy: "createTime DESC",
    );
    return List.generate(maps.length, (i) {
      return Photo.fromMap(maps[i]);
    });
  }

  /// 获取最近的部分照片
  Future<List<Photo>> getRecentPhotos(int count) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      "photos",
      orderBy: "createTime DESC",
      limit: count,
    );
    return List.generate(maps.length, (i) {
      return Photo.fromMap(maps[i]);
    });
  }

  /// 获取对应相册的图片列表
  Future<List<Photo>> getAlbumPhotos(String category) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'imagePath LIKE ?',
      whereArgs: ['%$category%'],
      orderBy: "createTime DESC",
      limit: 50, // 测试环境
    );

    return List.generate(maps.length, (i) {
      return Photo.fromMap(maps[i]);
    });
  }

  /// 获取相册组件的封面图
  Future<String> getAlbumFirstPhotoPath(String category) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'imagePath LIKE ?',
      whereArgs: ['%$category%'],
      orderBy: "createTime DESC",
    );

    if (maps.isNotEmpty) {
      Photo photo = Photo.fromMap(maps[0]);
      return photo.imagePath;
    } else {
      return ''; // 返回一个空字符串或其他默认值，表示没有图片
    }
  }

  /// 获取应用相册的所有父级路径
  Future<List<String>> getAppAlbumPathNames() async {
    // 获取所有路径
    final List<Map<String, dynamic>> maps = await _database!.rawQuery(
      "SELECT imagePath FROM photos",
    );

    // 解析路径中的父级目录
    var list = List.generate(maps.length, (i) {
      String imagePath = maps[i]['imagePath'] as String;
      var split = imagePath.split(Platform.pathSeparator);
      return split[split.length - 2];
    });

    // 筛选不再系统列表中的路径相册名称
    return list.where((element) => !['Camera'].contains(element)).toSet().toList();
  }

  /// 新增一条photo数据
  Future<int> insertPhoto(Photo photo) async {
    Database db = await database;
    return await db.insert("photos", photo.toMap());
  }
}
