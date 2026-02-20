class OfferModel {
  final int? id;
  final int? userId;
  final int? educationId;
  final String? nameOffer;
  final String? numberOfSessions;
  final String? hour1;
  final double? price1;
  final String? hour2;
  final double? price2;

  final OfferImageModel? offerImage;

  OfferModel({
    this.id,
    this.userId,
    this.educationId,
    this.nameOffer,
    this.numberOfSessions,
    this.hour1,
    this.price1,
    this.hour2,
    this.price2,
    this.offerImage,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      userId: json['user_id'],
      educationId: json['education_id'],
      nameOffer: json['name_offer'],
      numberOfSessions: json['number_of_sessions'],
      hour1: json['hour1'],
      price1: json['price1'] != null
          ? double.tryParse(json['price1'].toString())
          : null,
      hour2: json['hour2'],
      price2: json['price2'] != null
          ? double.tryParse(json['price2'].toString())
          : null,
      offerImage: json['offer_image'] != null
          ? OfferImageModel.fromJson(json['offer_image'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'education_id': educationId,
      'name_offer': nameOffer,
      'number_of_sessions': numberOfSessions,
      'hour1': hour1,
      'price1': price1,
      'hour2': hour2,
      'price2': price2,
      'offer_image': offerImage?.toJson(),
    };
  }

  double get price {
    if (price1 != null) return price1!;
    if (price2 != null) return price2!;
    return 0.0.toDouble();
  }

  double get hours {
    if (hour1 != null) return 1.5.toDouble();
    if (hour2 != null) return 2.0.toDouble();
    return 2.0.toDouble();
  }
}

class OfferImageModel {
  final int? id;
  final String? fileName;
  final String? url;
  final String? thumbnail;
  final String? previewThumbnail;

  OfferImageModel({
    this.id,
    this.fileName,
    this.url,
    this.thumbnail,
    this.previewThumbnail,
  });

  factory OfferImageModel.fromJson(Map<String, dynamic> json) {
    return OfferImageModel(
      id: json['id'],
      fileName: json['file_name'],
      url: json['url'],
      thumbnail: json['thumbnail'],
      previewThumbnail: json['preview_thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'url': url,
      'thumbnail': thumbnail,
      'preview_thumbnail': previewThumbnail,
    };
  }
}
