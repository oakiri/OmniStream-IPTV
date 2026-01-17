import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

@HiveType(typeId: 10)
class CategoryModel extends Equatable {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<String> channels;

  const CategoryModel({
    required this.name,
    required this.channels,
  });

  @override
  List<Object?> get props => [name, channels];
}

/// Adapter manual para evitar depender de archivos generados (*.g.dart).
class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 10;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      name: fields[0] as String,
      channels: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.channels);
  }
}
