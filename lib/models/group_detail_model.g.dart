// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_detail_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupDetailModelAdapter extends TypeAdapter<GroupDetailModel> {
  @override
  final int typeId = 0;

  @override
  GroupDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupDetailModel()
      ..groupCode = fields[0] as String
      ..groupName = fields[1] as String
      ..members = (fields[2] as List)
          .map((dynamic e) => (e as Map).cast<String, String>())
          .toList()
      ..isUserCreator = fields[3] as bool
      ..lastUpdated = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, GroupDetailModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.groupCode)
      ..writeByte(1)
      ..write(obj.groupName)
      ..writeByte(2)
      ..write(obj.members)
      ..writeByte(3)
      ..write(obj.isUserCreator)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupDetailModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
