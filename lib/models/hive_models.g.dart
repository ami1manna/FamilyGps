// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDetailModelAdapter extends TypeAdapter<UserDetailModel> {
  @override
  final int typeId = 1;

  @override
  UserDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserDetailModel(
      userId: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      lat: fields[3] as double?,
      long: fields[4] as double?,
      groupIds: (fields[5] as List?)?.cast<String>(),
      status: fields[6] as String,
      lastUpdatedLocation: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserDetailModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.long)
      ..writeByte(5)
      ..write(obj.groupIds)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.lastUpdatedLocation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDetailModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupDetailModelAdapter extends TypeAdapter<GroupDetailModel> {
  @override
  final int typeId = 3;

  @override
  GroupDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupDetailModel(
      groupCode: fields[0] as String,
      groupName: fields[1] as String,
      creatorId: fields[2] as String,
      members: (fields[3] as List?)?.cast<String>(),
      lastUpdated: fields[5] as DateTime?,
    );
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
      ..write(obj.creatorId)
      ..writeByte(3)
      ..write(obj.members)
      ..writeByte(5)
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
