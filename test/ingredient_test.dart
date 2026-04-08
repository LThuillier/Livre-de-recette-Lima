import 'package:flutter_test/flutter_test.dart';
import 'package:livre_de_recettes/models/ingredient.dart';

void main() {
  group('TDD - Ingredient.toString()', () {
    test('retourne quantite entiere sans .0', () {
      final ingredient = Ingredient(name: 'Farine', quantity: 200, unit: 'g');

      final result = ingredient.toString();

      expect(result, '200 g de Farine');
    });

    test('garde la partie decimale quand la quantite a une virgule', () {
      final ingredient = Ingredient(name: 'Lait', quantity: 1.5, unit: 'L');

      final result = ingredient.toString();

      expect(result, '1.5 L de Lait');
    });

    test('n ajoute pas "de" quand unite est vide', () {
      final ingredient = Ingredient(name: 'Pommes', quantity: 3, unit: '');

      final result = ingredient.toString();

      expect(result, '3 Pommes');
    });

    test('retourne seulement le nom quand quantite et unite sont absentes', () {
      final ingredient = Ingredient(name: 'Sucre', quantity: 0, unit: '');

      final result = ingredient.toString();

      expect(result, 'Sucre');
    });

    test('retire les espaces de bord quand quantite est absente mais unite presente', () {
      final ingredient = Ingredient(name: 'Beurre', quantity: 0, unit: 'g');

      final result = ingredient.toString();

      expect(result, 'g de Beurre');
    });
  });
}
