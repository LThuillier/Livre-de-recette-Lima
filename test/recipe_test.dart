import 'package:flutter_test/flutter_test.dart';
import 'package:livre_de_recettes/models/ingredient.dart';
import 'package:livre_de_recettes/models/recipe.dart';

void main() {
  group('Feature: creer une recette', () {
    test(
      'Scenario: Given champs obligatoires seulement, When je cree la recette, Then les valeurs par defaut sont appliquees',
      () {
        final recipe = Recipe(
          id: '123-abc',
          title: 'Gateau au chocolat',
          category: 'Sucre',
          label: 'Nouveau',
          imageUrl: 'assets/pictures/gateau.png',
          createdAt: DateTime(2026, 4, 8),
          ingredients: [],
        );

        expect(recipe.part, MealPart.plat);
        expect(recipe.description, '');
      },
    );

    test(
      'Scenario: Given une recette existante, When j ajoute un ingredient, Then la liste est mise a jour',
      () {
        final recipe = Recipe(
          id: '456-def',
          title: 'Omelette',
          category: 'Sale-Veggie',
          label: '',
          imageUrl: '',
          createdAt: DateTime(2026, 4, 8),
          ingredients: [
            Ingredient(name: 'Oeufs', quantity: 3, unit: 'pieces'),
          ],
        );

        recipe.ingredients.add(
          Ingredient(name: 'Sel', quantity: 1, unit: 'pincee'),
        );

        expect(recipe.ingredients.length, 2);
        expect(recipe.ingredients.last.name, 'Sel');
      },
    );
  });

  group('Feature: afficher les parties du repas', () {
    test(
      'Scenario: Given les types de repas, When je lis les labels, Then ils sont non vides',
      () {
        expect(MealPart.entree.label.trim().isNotEmpty, isTrue);
        expect(MealPart.plat.label.trim().isNotEmpty, isTrue);
        expect(MealPart.dessert.label.trim().isNotEmpty, isTrue);
      },
    );
  });
}
