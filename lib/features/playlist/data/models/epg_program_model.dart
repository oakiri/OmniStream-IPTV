import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

@HiveType(typeId: 2)
class EPGProgramModel extends Equatable {
  @HiveField(0)
  final String channelId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime start;

  @HiveField(4)
  final DateTime end;

  const EPGProgramModel({
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [channelId, title, description, start, end];
}

class EPGProgramModelAdapter extends TypeAdapter<EPGProgramModel> {
  @override
  final int typeId = 2;

  @override
  EPGProgramModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return EPGProgramModel(
      channelId: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      start: fields[3] as DateTime,
      end: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EPGProgramModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.start)
      ..writeByte(4)
      ..write(obj.end);
  }
}
