import 'package:hive_flutter/hive_flutter.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 1)
class UserDetailModel extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  double? lat;

  @HiveField(4)
  double? long;

  @HiveField(5)
  List<String>? groupIds;

  @HiveField(6)
  String status;

  @HiveField(7)
  DateTime? lastUpdatedLocation;

  UserDetailModel({
    required this.userId,
    required this.name,
    required this.email,
    this.lat,
    this.long,
    List<String>? groupIds,
    this.status = 'offline',
    DateTime? lastUpdatedLocation,
  }) {
    this.groupIds = groupIds ?? [];
  }
}
@HiveType(typeId: 3)
class GroupDetailModel extends HiveObject {
  @HiveField(0)
  late String groupCode;

  @HiveField(1)
  late String groupName;

  @HiveField(2)
  late String creatorId;

  @HiveField(3)
  late List<String> members;

   

  @HiveField(5)
  late DateTime lastUpdated;

  GroupDetailModel({
    required this.groupCode,
    required this.groupName,
    required this.creatorId,
    List<String>? members,

    DateTime? lastUpdated,
  }) {
    this.members = members ?? [];
    this.lastUpdated = lastUpdated ?? DateTime.now();
  }

  // Optional: Method to update last updated time
  void updateLastUpdated() {
    lastUpdated = DateTime.now();
  }
}

class StringListAdapter extends TypeAdapter<List<String>> {
  @override
  final typeId = 4;

  @override
  List<String> read(BinaryReader reader) {
    final length = reader.readInt();
    return List.generate(length, (_) => reader.readString());
  }

  @override
  void write(BinaryWriter writer, List<String> obj) {
    writer.writeInt(obj.length);
    for (var item in obj) {
      writer.writeString(item);
    }
  }
}
