class LibCommentModel {
  final int id;
  final String body;
  final int userId;
  final int libItemId;

  LibCommentModel({
    required this.id,
    required this.body,
    required this.userId,
    required this.libItemId,
  });

  factory LibCommentModel.fromJson(Map<String, dynamic> json) {
    return LibCommentModel(
      id: json['id'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      userId: json['user_id'] as int? ?? 0,
      libItemId: json['lib_item_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'user_id': userId,
      'lib_item_id': libItemId,
    };
  }
}