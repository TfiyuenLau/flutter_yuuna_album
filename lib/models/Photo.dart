
/// # SQLite存储图片元数据对象
///
/// * [id]: 图片的唯一标识符，自增长整数。
/// * [filename]: 图片文件名。
/// * [imagePath]: 图片文件在文件系统中的路径。
/// * [createTime]: 图片的创建时间，使用DATETIME类型。
/// * [updateTime]: 图片的修改时间，使用DATETIME类型。
/// * [timestamp]: 图片插入数据库的时间，使用int类型记录时间戳。
/// * [width]: 图片的宽度。
/// * [height]: 图片的高度。
/// * [fileSize]: 图片文件大小(MB)。
/// * [status]: 图片当前的状态：100：未分类，101：已进行一般标签分类，102：已进行人像分类（聚类）。
/// * [tags]: 图片的标签或分类信息，可以用逗号分隔的字符串或者使用另外的表进行关联。
class Photo {
  int? id;
  String filename;
  String imagePath;
  DateTime? createTime;
  DateTime? updateTime;
  int? timestamp;
  int? width;
  int? height;
  double? fileSize;
  int? status;
  String? tags;

  Photo({
    this.id,
    required this.filename,
    required this.imagePath,
    this.createTime,
    this.updateTime,
    this.timestamp,
    this.width,
    this.height,
    this.fileSize,
    this.status,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'imagePath': imagePath,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'timestamp': timestamp,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'status': status,
      'tags': tags,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      filename: map['filename'],
      imagePath: map['imagePath'],
      createTime: map['createTime'] != null ? DateTime.tryParse(map['createTime']!.toString()) : null,
      updateTime: map['updateTime'] != null ? DateTime.tryParse(map['updateTime']!.toString()) : null,
      timestamp: map['timestamp'],
      width: map['width'],
      height: map['height'],
      fileSize: map['fileSize'],
      status: map['status'],
      tags: map['tags'],
    );
  }
}
