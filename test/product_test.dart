import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/models/product.dart';

void main() {
  group('Product.fromJson', () {
    test('parses eco/nutri grade and score', () {
      final p = Product.fromJson('3175680011480', {
        'product_name': 'Sésame',
        'ecoscore_grade': 'c',
        'ecoscore_score': 54,
        'nutriscore_grade': 'c',
        'origins': 'France',
      });
      expect(p.name, 'Sésame');
      expect(p.ecoGrade, 'c');
      expect(p.ecoScore, 54);
      expect(p.nutriGrade, 'c');
      expect(p.isPoorEco, isFalse);
      expect(p.isSustainable, isFalse);
    });

    test('falls back to localized name when product_name is empty', () {
      final p = Product.fromJson('1', {
        'product_name': '',
        'product_name_en': 'Cookies',
        'ecoscore_grade': 'e',
      });
      expect(p.name, 'Cookies');
      expect(p.isPoorEco, isTrue);
    });

    test('handles not-applicable grade with missing score', () {
      final p = Product.fromJson('5449000000996', {
        'product_name': 'Coca-Cola',
        'ecoscore_grade': 'not-applicable',
      });
      expect(p.ecoGrade, 'not-applicable');
      expect(p.ecoScore, isNull);
      expect(p.isPoorEco, isFalse);
      expect(p.isSustainable, isFalse);
    });

    test('an a/b grade is sustainable', () {
      final p = Product.fromJson('1', {
        'product_name': 'Veggies',
        'ecoscore_grade': 'a',
        'ecoscore_score': 95,
      });
      expect(p.isSustainable, isTrue);
    });

    test('missing name defaults to Unknown product', () {
      final p = Product.fromJson('1', {'ecoscore_grade': 'b'});
      expect(p.name, 'Unknown product');
    });

    test('falls back to environmental_score_grade when ecoscore_grade absent',
        () {
      final p = Product.fromJson('1', {
        'product_name': 'New OFF product',
        'environmental_score_grade': 'a',
      });
      expect(p.ecoGrade, 'a');
      expect(p.isSustainable, isTrue);
    });

    test('uses product_name_fr fallback', () {
      final p = Product.fromJson('1', {
        'product_name': '',
        'product_name_fr': 'Biscuits',
        'ecoscore_grade': 'c',
      });
      expect(p.name, 'Biscuits');
    });

    test('non-numeric ecoscore_score becomes null', () {
      final p = Product.fromJson('1', {
        'product_name': 'X',
        'ecoscore_grade': 'c',
        'ecoscore_score': 'oops',
      });
      expect(p.ecoScore, isNull);
    });

    test('grade is normalized to lower case (uppercase A is sustainable)', () {
      final p = Product.fromJson('1', {
        'product_name': 'X',
        'ecoscore_grade': 'A',
      });
      expect(p.ecoGrade, 'a');
      expect(p.isSustainable, isTrue);
    });
  });
}
