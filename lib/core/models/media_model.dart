class MediaModel {
  final int id;
  final String? name;
  final String fileName;
  final String? mimeType;
  final String disk;
  final int size;
  final String? manipulations;
  final String? customProperties;
  final String? generatedConversions;
  final String? responsiveImages;
  final int? orderColumn;
  final String url; // Assuming you'll calculate or fetch this
  // Add other relevant fields as needed (e.g., createdAt, updatedAt if required)

  MediaModel({
    required this.id,
    this.name,
    required this.fileName,
    this.mimeType,
    required this.disk,
    required this.size,
    this.manipulations,
    this.customProperties,
    this.generatedConversions,
    this.responsiveImages,
    this.orderColumn,
    required this.url, // Pass the URL when creating the object
  });

  // Basic fromJson constructor (you'll need to adapt based on your API response)
  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      fileName: json['file_name'] as String? ?? '',
      mimeType: json['mime_type'] as String?,
      disk: json['disk'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      url: json['original_url'] as String? ?? '', // Adjust key if needed
    );
  }

  // Basic toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_name': fileName,
      'mime_type': mimeType,
      'disk': disk,
      'size': size,
      'custom_properties': customProperties,
      'generated_conversions': generatedConversions,
      'responsive_images': responsiveImages,
      'order_column': orderColumn,
      'url': url,
    };
  }
}