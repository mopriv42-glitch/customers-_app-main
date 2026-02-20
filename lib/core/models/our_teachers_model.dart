class OurTeacherImage {
  final String? url;
  final String? thumbnail;
  final String? previewThumbnail;

  OurTeacherImage({
    this.url,
    this.thumbnail,
    this.previewThumbnail,
  });

  factory OurTeacherImage.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OurTeacherImage();

    return OurTeacherImage(
      url: json['url'] as String?,
      thumbnail: json['thumbnail'] as String?,
      previewThumbnail: json['preview_thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'thumbnail': thumbnail,
      'preview_thumbnail': previewThumbnail,
    };
  }
}

class OurTeacher {
  final int id;
  final String title;
  final String body;
  final int? subjectId;
  final OurTeacherImage? ourTeacherImage;

  OurTeacher({
    required this.id,
    required this.title,
    required this.body,
    this.subjectId,
    this.ourTeacherImage,
  });

  factory OurTeacher.fromJson(Map<String, dynamic> json) {
    return OurTeacher(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      subjectId: json['subject_id'] as int?,
      ourTeacherImage: OurTeacherImage.fromJson(
          json['our_teacher_image'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'subject_id': subjectId,
      'our_teacher_image': ourTeacherImage?.toJson(),
    };
  }
}

class OurTeachersResponse {
  final List<OurTeacher> teachers;

  OurTeachersResponse({
    required this.teachers,
  });

  factory OurTeachersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final teachersJson = data['teachers'] as List<dynamic>? ?? [];

    final teachers = teachersJson
        .map((teacherJson) =>
            OurTeacher.fromJson(teacherJson as Map<String, dynamic>))
        .toList();

    return OurTeachersResponse(teachers: teachers);
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'teachers': teachers.map((teacher) => teacher.toJson()).toList(),
      },
    };
  }
}
