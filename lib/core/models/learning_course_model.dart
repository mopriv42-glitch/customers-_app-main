import 'package:private_4t_app/core/models/lms_lesson_model.dart';

class LearningCourseModel {
  final int? id;
  final String title;
  final String slug;
  final String? description;
  final String? shortDescription;
  final double price;
  final double? discountPrice;
  final int? duration;
  final String? level;
  final String? status;
  final String? matrixRoomId;
  final bool featured;
  final bool popular;
  final int? categoryId;
  final int? instructorId;
  final int? totalLessons;
  final int? totalStudents;
  final int totalRatings;
  final double averageRating;
  final List<String>? requirements;
  final List<String>? whatYouWillLearn;
  final List<String>? targetAudience;
  final bool certificateIncluded;
  final bool lifetimeAccess;
  final String? language;
  final String? subtitleLanguage;
  final DateTime? lastUpdated;
  final String? difficultyLevel;
  final int? totalSteps;
  final int? views;
  final String? previewUrl;
  final int? moodleCourseId;
  final String? features;
  final bool enableDiscount;

  // Computed or appended attributes
  final String? thumbnailUrl;
  final String? videoThumbnailUrl;
  final String? formattedPrice;
  final String? formattedDiscountPrice;
  final int? discountPercentage;
  final Map<String, dynamic>? ratingStars;
  final int? enrollmentCount;
  final double? completionRate;
  final bool? isCartable;
  final String? moodleCourseLink;
  final bool? isEnrolled;
  final bool? isSaved;
  final String? categoryName;

  final List<LmsLessonModel>? lessons;

  LearningCourseModel({
    this.id,
    required this.title,
    required this.slug,
    this.description,
    this.shortDescription,
    required this.price,
    this.discountPrice,
    this.duration,
    this.level,
    this.status,
    required this.featured,
    required this.popular,
    this.categoryId,
    this.instructorId,
    this.totalLessons,
    this.totalStudents,
    required this.totalRatings,
    required this.averageRating,
    this.requirements,
    this.whatYouWillLearn,
    this.targetAudience,
    required this.certificateIncluded,
    required this.lifetimeAccess,
    this.language,
    this.subtitleLanguage,
    this.lastUpdated,
    this.difficultyLevel,
    this.totalSteps,
    this.views,
    this.previewUrl,
    this.moodleCourseId,
    this.features,
    this.matrixRoomId,
    required this.enableDiscount,
    this.thumbnailUrl,
    this.videoThumbnailUrl,
    this.formattedPrice,
    this.formattedDiscountPrice,
    this.discountPercentage,
    this.ratingStars,
    this.enrollmentCount,
    this.completionRate,
    this.isCartable,
    this.moodleCourseLink,
    this.isEnrolled,
    this.isSaved,
    this.categoryName,
    this.lessons,
  });

  factory LearningCourseModel.fromJson(Map<String, dynamic> json) {
    return LearningCourseModel(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      description: json['description'],
      shortDescription: json['short_description'],
      price: (num.tryParse(json['price']) ?? 0).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (num.tryParse(json['discount_price']) ?? 0).toDouble()
          : null,
      duration: json['duration'],
      level: json['level'],
      status: json['status'],
      featured: json['featured'] ?? false,
      popular: json['popular'] ?? false,
      categoryId: json['category_id'],
      instructorId: json['instructor_id'],
      matrixRoomId: json['matrix_room_id'],
      totalLessons: json['total_lessons'],
      totalStudents: json['total_students'],
      totalRatings: json['total_ratings'] ?? 0,
      averageRating:
          (num.tryParse("${json['average_rating']}"))?.toDouble() ?? 0.0,
      requirements:
          (json['requirements'] as List?)?.map((e) => e.toString()).toList(),
      whatYouWillLearn: (json['what_you_will_learn'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      targetAudience:
          (json['target_audience'] as List?)?.map((e) => e.toString()).toList(),
      certificateIncluded: json['certificate_included'] ?? false,
      lifetimeAccess: json['lifetime_access'] ?? false,
      language: json['language'],
      subtitleLanguage: json['subtitle_language'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      difficultyLevel: json['difficulty_level'],
      totalSteps: json['total_steps'],
      views: json['views'],
      previewUrl: json['preview_url'],
      moodleCourseId: json['moodle_course_id'],
      features: json['features'],
      enableDiscount: json['enable_discount'] ?? false,
      thumbnailUrl: json['thumbnail_url'],
      videoThumbnailUrl: json['video_thumbnail_url'],
      formattedPrice: json['formatted_price'],
      formattedDiscountPrice: json['formatted_discount_price'],
      discountPercentage: json['discount_percentage'],
      ratingStars: json['rating_stars'],
      enrollmentCount: json['enrollment_count'],
      completionRate: (json['completion_rate'] as num?)?.toDouble(),
      isCartable: json['is_cartable'],
      moodleCourseLink: json['moodle_course_link'],
      isEnrolled: json['is_enrolled'],
      isSaved: json['is_saved'],
      categoryName: json['category_name'],
      lessons: json['lessons'] != null
          ? List<LmsLessonModel>.from(
              json['lessons'].map((x) => LmsLessonModel.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'price': price,
      'discount_price': discountPrice,
      'duration': duration,
      'level': level,
      'status': status,
      'featured': featured,
      'popular': popular,
      'category_id': categoryId,
      'instructor_id': instructorId,
      'total_lessons': totalLessons,
      'total_students': totalStudents,
      'total_ratings': totalRatings,
      'average_rating': averageRating,
      'requirements': requirements,
      'what_you_will_learn': whatYouWillLearn,
      'target_audience': targetAudience,
      'certificate_included': certificateIncluded,
      'lifetime_access': lifetimeAccess,
      'language': language,
      'subtitle_language': subtitleLanguage,
      'last_updated': lastUpdated?.toIso8601String(),
      'difficulty_level': difficultyLevel,
      'total_steps': totalSteps,
      'views': views,
      'preview_url': previewUrl,
      'moodle_course_id': moodleCourseId,
      'features': features,
      'enable_discount': enableDiscount,
      'thumbnail_url': thumbnailUrl,
      'video_thumbnail_url': videoThumbnailUrl,
      'formatted_price': formattedPrice,
      'formatted_discount_price': formattedDiscountPrice,
      'discount_percentage': discountPercentage,
      'rating_stars': ratingStars,
      'enrollment_count': enrollmentCount,
      'matrix_room_id': matrixRoomId,
      'completion_rate': completionRate,
      'is_cartable': isCartable,
      'moodle_course_link': moodleCourseLink,
      'is_enrolled': isEnrolled,
      'is_saved': isSaved,
      'category_name': categoryName,
      'lessons': lessons?.map((x) => x.toJson()).toList(),
    };
  }
}
