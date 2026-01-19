class CourseData {
  final String id;
  final String title;
  final String subject;
  final double price;
  final double originalPrice;
  final String image;
  final List<String> features;

  CourseData({
    required this.id,
    required this.title,
    required this.subject,
    required this.price,
    required this.originalPrice,
    required this.image,
    required this.features,
  });
}
