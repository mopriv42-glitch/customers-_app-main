class ClipCommentUser {
  final int id;
  final String name;
  ClipCommentUser({required this.id, required this.name});
  factory ClipCommentUser.fromJson(Map<String, dynamic> json) =>
      ClipCommentUser(
          id: json['id'] ?? 0, name: json['name']?.toString() ?? '');
}

class ClipCommentModel {
  final int id;
  final String content;
  final ClipCommentUser user;
  final String createdAt;
  final int? parentId;
  final List<ClipCommentModel> replies;

  ClipCommentModel({
    required this.id,
    required this.content,
    required this.user,
    required this.createdAt,
    this.parentId,
    this.replies = const [],
  });

  factory ClipCommentModel.fromJson(Map<String, dynamic> json) {
    final repliesJson = (json['replies'] as List?) ?? const [];
    return ClipCommentModel(
      id: json['id'] ?? 0,
      content: json['content']?.toString() ?? '',
      user: ClipCommentUser.fromJson(
          (json['user'] as Map?)?.cast<String, dynamic>() ?? {}),
      createdAt: json['created_at']?.toString() ?? '',
      parentId: json['parent_id'],
      replies: repliesJson
          .map((e) =>
              ClipCommentModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}
