import 'package:equatable/equatable.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';

abstract class PlaylistProfileEvent extends Equatable {
  const PlaylistProfileEvent();

  @override
  List<Object> get props => [];
}

class GetProfilesEvent extends PlaylistProfileEvent {}

class AddProfileEvent extends PlaylistProfileEvent {
  final PlaylistProfile profile;

  const AddProfileEvent(this.profile);

  @override
  List<Object> get props => [profile];
}

class DeleteProfileEvent extends PlaylistProfileEvent {
  final String id;

  const DeleteProfileEvent(this.id);

  @override
  List<Object> get props => [id];
}
