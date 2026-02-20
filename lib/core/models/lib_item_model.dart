import 'package:private_4t_app/core/models/lib_comment_model.dart';
import 'package:private_4t_app/core/models/lib_sub_section_model.dart';
import 'package:private_4t_app/core/models/media_model.dart';

class LibItemModel {
  final int id;
  final String name;
  final String? description;
  final String? externalLink;
  final String itemType;
  final String? placeholderLink;
  final int libSubSectionId;

  // Appended Attributes
  final MediaModel? file; // Based on getFileAttribute()
  final LibSubSectionModel? subSection;
  final List<LibCommentModel>? comments;

  LibItemModel({
    required this.id,
    required this.name,
    this.description,
    this.externalLink,
    required this.itemType,
    this.placeholderLink,
    required this.libSubSectionId,
    this.file,
    this.subSection,
    this.comments,
  });

  factory LibItemModel.fromJson(Map<String, dynamic> json) {
    return LibItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      externalLink: json['external_link'] as String?,
      itemType: json['item_type'] as String? ?? '',
      placeholderLink: json['placeholder_link'] as String?,
      libSubSectionId: json['lib_sub_section_id'] as int? ?? 0,
      file: json['file'] != null
          ? MediaModel.fromJson(json['file'] as Map<String, dynamic>)
          : null,
      subSection: json['sub_section'] != null
          ? LibSubSectionModel.fromJson(
              json['sub_section'] as Map<String, dynamic>)
          : null,
      comments: json['comments'] != null
          ? List<LibCommentModel>.from(
              json['comments'].map(
                (c) => LibCommentModel.fromJson(c),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'external_link': externalLink,
      'item_type': itemType,
      'placeholder_link': placeholderLink,
      'lib_sub_section_id': libSubSectionId,
      'file': file?.toJson(),
      'sub_section': subSection?.toJson(),
      'comments': comments?.map((c) => c.toJson()).toList(),
    };
  }
}
