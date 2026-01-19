class LibSectionModel {
  final int id;
  final String name;
  final String? slug;
  final String? icon;
  final String? description;

  LibSectionModel({
    required this.id,
    required this.name,
    this.slug,
    this.icon,
    this.description,
  });

  factory LibSectionModel.fromJson(Map<String, dynamic> json) {
    return LibSectionModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'description': description,
    };
  }
}