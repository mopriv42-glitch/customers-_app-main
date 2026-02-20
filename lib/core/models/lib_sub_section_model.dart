import 'package:private_4t_app/core/models/lib_item_model.dart';

class LibSubSectionModel {
  final int id;
  final String name;
  final String? slug;
  final int? parentId;

  // Appended Attributes
  final String? thumbnail; // Based on getThumbnailAttribute() - URL string
  final List<LibItemModel>? items;

  LibSubSectionModel({
    required this.id,
    required this.name,
    this.slug,
    this.parentId,
    this.thumbnail,
    this.items,
  });

  factory LibSubSectionModel.fromJson(Map<String, dynamic> json) {
    return LibSubSectionModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      parentId: json['parent_id'] as int?,
      items: json['items'] != null
          ? List<LibItemModel>.from(
              json['items'].map(
                (c) => LibItemModel.fromJson(c),
              ),
            )
          : [],
      thumbnail: json['thumbnail']
          as String?, // Assuming API returns the URL string directly
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parent_id': parentId,
      'thumbnail': thumbnail,
      'items': items?.map((i) => i.toJson()).toList(),
    };
  }
}
