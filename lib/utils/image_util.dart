import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:exif/exif.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as image_util;

import '../models/Photo.dart';
import '../services/photos_service.dart';

/// 加载外部存储的图片插入数据库
void loadPhotosInsertDB() async {
  // 扫描获取外部存储除Android的目录集合
  PhotosService photosService = PhotosService();
  Stream<FileSystemEntity> dirList = Directory('/storage/emulated/0').list().where(
      (event) => event is Directory && !event.path.startsWith("/storage/emulated/0/Android")
  );
  // dirList.forEach((element) {log(element.path);});

  // 获取图片信息并封装photo对象插入数据库中
  await for (var dir in dirList) {
    dir = dir as Directory;
    Stream<FileSystemEntity> entities = dir.list(recursive: true);
    await for (final imageFile in entities) {
      if (imageFile is File && isImage(imageFile)) {
        var pathSplit = imageFile.path.split("/");
        late int width;
        late int height;
        DateTime? createTime;
        DateTime? updateTime;

        Uint8List imageBytes = await imageFile.readAsBytes();
        image_util.Image? image = image_util.decodeImage(imageBytes);
        if (image != null) {
          // 获取图片的宽度和高度
          width = image.width;
          height = image.height;

          // 获取EXIF数据
          List<int>? exifData = await imageFile.readAsBytes();
          Map<String, dynamic>? tags = await readExifFromBytes(exifData);

          if (tags.isNotEmpty) {
            // 打印图片的所有EXIF信息
            // for (final entry in tags.entries) {
            //   log("${entry.key}: ${entry.value}");
            // }

            // 解析图片时间
            DateFormat format = DateFormat("yyyy:MM:dd HH:mm:ss");
            if (tags.containsKey("Image DateTime")) {
              // 图片修改时间
              IfdTag? dateTimeTag = tags["Image DateTime"];
              updateTime = format.parse(dateTimeTag!.printable);
            } else {
              updateTime = null;
            }
            if (tags.containsKey("EXIF DateTimeDigitized")) {
              // 图片创建时间
              IfdTag? dateTimeTag = tags["EXIF DateTimeDigitized"];
              createTime = format.parse(dateTimeTag!.printable);
            } else {
              createTime = updateTime;
            }
          }

          // 封装并插入sqlite数据库
          try {
            final Map<String, dynamic> photoMap = {
              "filename": pathSplit[pathSplit.length - 1],
              "imagePath": imageFile.path,
              "createTime": createTime,
              "updateTime": updateTime,
              "timestamp": DateTime.now().millisecondsSinceEpoch,
              "width": width,
              "height": height,
              "fileSize": imageFile.lengthSync() / 1024 / 1024,
              "status": 100, // 未分类
            };
            // log(photoMap.toString());

            final photo = Photo.fromMap(photoMap);
            photosService.insertPhoto(photo);
          } catch (e) {
            log(e.toString());
          }
        }
      }
    }
    log("Images loaded");
  }
}

/// 获取图片创建时间
Future<String?> getPhotoCreateTime(File file) async {
  try {
    // 获取EXIF数据
    Map<String, dynamic>? tags = await readExifFromFile(file);
    // tags.forEach((key, value) {log("$key:$value");});

    // 获取图片创建时间
    if (tags.containsKey("EXIF DateTimeOriginal")) {
      IfdTag? dateTimeTag = tags["EXIF DateTimeOriginal"];
      return dateTimeTag?.printable;
    } else {
      if (tags.containsKey("Image DateTime")) {
        IfdTag? dateTimeTag = tags["Image DateTime"];
        return dateTimeTag?.printable;
      } else {
        return null;
      }
    }
  } catch (e) {
    log("Error getting photo create time: $e");
    return null;
  }
}

/// 使用mime判断文件类型是否为图片
bool isImage(File file) {
  final mimeType = lookupMimeType(file.path);
  return mimeType != null && mimeType.startsWith('image');
}


/// 将图片按日期进行分组
Future<Map<String, List<File>>> groupImagesByDate(List<File> images) async {
  Map<String, List<File>> groupedImages = {};

  for (final image in images) {
    String date = await getFormattedDateTime(image);
    if (!groupedImages.containsKey(date)) {
      groupedImages[date] = [];
    }
    groupedImages[date]!.add(image);
  }
  return groupedImages;
}

/// 获取图片的格式化日期
Future<String> getFormattedDateTime(File imageFile) async {
  String photoCreateTime = "UNKNOWN";
  String? createTime = await getPhotoCreateTime(imageFile);

  if (createTime != null) {
    DateFormat format = DateFormat("yyyy:MM:dd HH:mm:ss");
    DateTime dateTime = format.parse(createTime);

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (dateTime.isAtSameMomentAs(today)) {
      photoCreateTime = "今天";
    } else if (dateTime.isAtSameMomentAs(yesterday)) {
      photoCreateTime = "昨天";
    } else {
      photoCreateTime = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    }
  }

  return photoCreateTime;
}

/// 获取图片尺寸
Future<Size> getImageSize(File imageFile) async {
  final Completer<Size> completer = Completer<Size>();

  ImageProperties properties = await FlutterNativeImage.getImageProperties(imageFile.path);

  completer.complete(Size(
    properties.width!.toDouble(),
    properties.height!.toDouble(),
  ));

  return completer.future;
}
