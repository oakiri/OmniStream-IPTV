import 'package:json_annotation/json_annotation.dart';

part 'xtream_user_info_model.g.dart';

@JsonSerializable()
class XtreamUserInfoModel {
  final String username;
  final String password;
  final String? message;
  final int auth;
  final String status;
  @JsonKey(name: 'exp_date')
  final String? expDate;
  @JsonKey(name: 'is_trial')
  final String? isTrial;
  @JsonKey(name: 'active_cons')
  final int? activeCons;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'max_connections')
  final String? maxConnections;

  XtreamUserInfoModel({
    required this.username,
    required this.password,
    this.message,
    required this.auth,
    required this.status,
    this.expDate,
    this.isTrial,
    this.activeCons,
    this.createdAt,
    this.maxConnections,
  });

  factory XtreamUserInfoModel.fromJson(Map<String, dynamic> json) =>
      _$XtreamUserInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$XtreamUserInfoModelToJson(this);
}
