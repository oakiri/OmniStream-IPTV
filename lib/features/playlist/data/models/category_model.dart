import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
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
