/// Model for parsing Matrix credentials from server login response
class MatrixCredentialsModel {
  final String userId;
  final String accessToken;
  final String homeserver;

  MatrixCredentialsModel({
    required this.userId,
    required this.accessToken,
    required this.homeserver,
  });

  factory MatrixCredentialsModel.fromJson(Map<String, dynamic> json) {
    return MatrixCredentialsModel(
      userId: json['user_id'] ?? '',
      accessToken: json['access_token'] ?? '',
      homeserver: json['homeserver'] ?? 'https://matrix.private-4t.com',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'access_token': accessToken,
      'homeserver': homeserver,
    };
  }

  /// Check if credentials are valid (non-empty)
  bool get isValid =>
      userId.isNotEmpty && accessToken.isNotEmpty && homeserver.isNotEmpty;
}
