import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String name;
  final List<String> channels;

  const Category({
    required this.name,
    required this.channels,
  });

  @override
  List<Object?> get props => [name, channels];
}
