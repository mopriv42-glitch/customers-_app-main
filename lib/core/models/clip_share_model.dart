class ClipShareModel {
  final int id;
  final String? platform;
  final String? message;
  final String createdAt;

  ClipShareModel({
    required this.id,
    required this.platform,
    required this.message,
    required this.createdAt,
  });

  factory ClipShareModel.fromJson(Map<String, dynamic> json) => ClipShareModel(
        id: json['id'] ?? 0,
        platform: json['share_platform']?.toString(),
        message: json['share_message']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}
