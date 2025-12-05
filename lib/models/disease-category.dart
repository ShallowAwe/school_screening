import 'package:school_test/models/diseases_model.dart';

class DiseaseCategoryResponse {
  final int categoryId;
  final String categoryName;
  final List<Disease> diseases;

  DiseaseCategoryResponse({
    required this.categoryId,
    required this.categoryName,
    required this.diseases,
  });

  factory DiseaseCategoryResponse.fromJson(Map<String, dynamic> json) {
    return DiseaseCategoryResponse(
      categoryId: json['categoryId'] ?? 0, // ✅ Handle null
      categoryName: json['categoryName'] ?? 'Unknown Category', // ✅ Handle null
      diseases:
          (json['diseases'] as List<dynamic>?)
              ?.map((e) => Disease.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [], // ✅ Handle null
    );
  }
}
