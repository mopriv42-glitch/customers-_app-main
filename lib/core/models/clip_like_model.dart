class ClipLikeUser {
  final int id;
  final String name;
  ClipLikeUser({required this.id, required this.name});
  factory ClipLikeUser.fromJson(Map<String, dynamic> json) =>
      ClipLikeUser(id: json['id'] ?? 0, name: json['name']?.toString() ?? '');
}

class ClipLikeModel {
  final int id;
  final ClipLikeUser user;
  final String createdAt;
  ClipLikeModel(
      {required this.id, required this.user, required this.createdAt});
  factory ClipLikeModel.fromJson(Map<String, dynamic> json) => ClipLikeModel(
        id: json['id'] ?? 0,
        user: ClipLikeUser.fromJson(
            (json['user'] as Map?)?.cast<String, dynamic>() ?? {}),
        createdAt: json['created_at']?.toString() ?? '',
      );
}
