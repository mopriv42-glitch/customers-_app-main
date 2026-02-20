class ClipModel {
  final int id;
  final int userId;
  final String userName;
  final String title;
  final String description;
  final String sourceType;
  final String sourceUrl;
  final String videoUrl;
  final String thumbnailUrl;
  int viewCount;
  int likesCount;
  int commentsCount;
  int sharesCount;
  final bool isYoutube;
  final bool isUploaded;
  bool isLiked; // local state

  ClipModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.sourceType,
    required this.sourceUrl,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.viewCount,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isYoutube,
    required this.isUploaded,
    this.isLiked = false,
  });

  factory ClipModel.fromJson(Map<String, dynamic> json) {
    print(json);
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final counts = json['counts'] as Map? ?? {};
    return ClipModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? user['id'] ?? 0,
      userName: user['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      videoUrl:
          json['video_url']?.toString() ?? json['source_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      viewCount: json['view_count'] ?? 0,
      likesCount: json['likes_count'] ?? counts['likes'] ?? 0,
      commentsCount: json['comments_count'] ?? counts['comments'] ?? 0,
      sharesCount: json['shares_count'] ?? counts['shares'] ?? 0,
      isYoutube: (json['is_youtube'] ?? false) == true,
      isUploaded: (json['is_uploaded'] ?? false) == true,
      isLiked:
          (bool.tryParse("${json['is_liked'] ?? json['user_liked'] ?? ''}") ??
                  false) ==
              true,
    );
  }
}
