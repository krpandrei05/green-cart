class Product {
  final String barcode;
  final String name;
  final String ecoGrade;
  final int? ecoScore;
  final String nutriGrade;
  final String origin;
  final String imageUrl;

  const Product({
    required this.barcode,
    required this.name,
    required this.ecoGrade,
    required this.ecoScore,
    required this.nutriGrade,
    required this.origin,
    required this.imageUrl,
  });

  factory Product.fromJson(String barcode, Map<String, dynamic> p) {
    String name = (p['product_name'] ?? '').toString();
    if (name.isEmpty) {
      name = (p['product_name_en'] ?? p['product_name_fr'] ?? '').toString();
    }
    if (name.isEmpty) name = 'Unknown product';

    final rawScore = p['ecoscore_score'];
    final int? ecoScore = rawScore is num ? rawScore.toInt() : null;

    return Product(
      barcode: barcode,
      name: name,
      ecoGrade: (p['ecoscore_grade'] ?? p['environmental_score_grade'] ?? 'unknown')
          .toString()
          .toLowerCase(),
      ecoScore: ecoScore,
      nutriGrade: (p['nutriscore_grade'] ?? 'unknown').toString().toLowerCase(),
      origin: (p['origins'] ?? '').toString(),
      imageUrl: (p['image_front_small_url'] ?? '').toString(),
    );
  }

  bool get isPoorEco => ecoGrade == 'd' || ecoGrade == 'e' || ecoGrade == 'f';
  bool get isSustainable => ecoGrade == 'a' || ecoGrade == 'b';
}
