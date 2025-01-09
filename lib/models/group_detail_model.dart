import 'package:hive/hive.dart';

 part   'group_detail_model.g.dart';

// Code for the generated adapter

@HiveType(typeId: 0)
class GroupDetailModel extends HiveObject {
  @HiveField(0)
  late String groupCode;

  @HiveField(1)
  late String groupName;

  @HiveField(2)
  late List<Map<String, String>> members;

  @HiveField(3)
  late bool isUserCreator;

  @HiveField(4)
  late DateTime lastUpdated;
}


class MemberListAdapter extends TypeAdapter<List<Map<String, String>>> {
  @override
  final typeId = 1;  // Unique ID for the adapter

  @override
  List<Map<String, String>> read(BinaryReader reader) {
    final length = reader.readInt();
    List<Map<String, String>> list = [];
    for (int i = 0; i < length; i++) {
      list.add(Map<String, String>.from(reader.readMap()));
    }
    return list;
  }

  @override
  void write(BinaryWriter writer, List<Map<String, String>> obj) {
    writer.writeInt(obj.length);
    for (var item in obj) {
      writer.writeMap(item);
    }
  }
}
