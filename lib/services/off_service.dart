import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class OffService {
  static Future<Product?> fetchProduct(String barcode, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {
        'fields': 'code,product_name,product_name_en,product_name_fr,'
            'ecoscore_grade,ecoscore_score,nutriscore_grade,origins,'
            'image_front_small_url',
      },
    );
    final response = await httpClient.get(uri, headers: {
      // OFF needs a User-Agent
      'User-Agent': 'EcoScanMadrid/1.0 (student project)',
    });
    if (response.statusCode != 200) return null;
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['status'] != 1) return null;
    return Product.fromJson(barcode, body['product'] as Map<String, dynamic>);
  }
}
