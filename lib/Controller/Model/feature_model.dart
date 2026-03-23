/// Model for a category feature from the taxonomie API (e.g. Saju features).
/// Matches API shape: id, category_id, title, text, image.
class FeatureModel {
  final int id;
  final int categoryId;
  final String title;
  final String text;
  final String? image;

  FeatureModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.text,
    this.image,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) => FeatureModel(
        id: json["id"] as int? ?? 0,
        categoryId: json["category_id"] as int? ?? 0,
        title: json["title"]?.toString() ?? '',
        text: json["text"]?.toString() ?? '',
        image: json["image"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "category_id": categoryId,
        "title": title,
        "text": text,
        "image": image,
      };
}
