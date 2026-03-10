import 'package:flutter_test/flutter_test.dart';

// Importation de tes modèles
import '../lib/models/recipe.dart';
import '../lib/models/ingredient.dart';

void main() {
  // --- GROUPE 1 : Tests sur la création d'une Recette ---
  group('Test du modèle Recipe (Recette)', () {

    test('Une nouvelle recette a bien les bonnes valeurs par défaut (Owner et Part)', () {
      // 1. ARRANGEMENT : On crée une recette avec le minimum d'informations
      final recette = Recipe(
        id: '123-abc',
        title: 'Gâteau au chocolat',
        category: 'Sucré',
        label: 'Nouveau',
        imageUrl: 'assets/pictures/gateau.png',
        createdAt: DateTime.now(),
        ingredients: [],
      );

      // 2. ASSERTION : On vérifie que les valeurs par défaut se sont bien appliquées
      expect(recette.owner, 'Matéo Esteban', reason: "Le propriétaire par défaut doit être Matéo Esteban");
      expect(recette.part, MealPart.plat, reason: "Par défaut, une recette doit être un plat");
      expect(recette.description, '', reason: "La description doit être vide par défaut et non null");
    });

    test('Ajout et modification d\'ingrédients dans une recette', () {
      // 1. ARRANGEMENT : Une recette avec 1 seul ingrédient
      final recette = Recipe(
        id: '456-def',
        title: 'Omelette',
        category: 'Salé-Veggie',
        label: '',
        imageUrl: '',
        createdAt: DateTime.now(),
        ingredients: [
          Ingredient(name: 'Oeufs', quantity: 3, unit: 'pièces')
        ],
      );

      // On vérifie qu'il y a bien 1 ingrédient au départ
      expect(recette.ingredients.length, 1);

      // 2. ACTION : On ajoute du sel
      recette.ingredients.add(Ingredient(name: 'Sel', quantity: 1, unit: 'pincée'));

      // 3. ASSERTION : On vérifie que la recette contient bien 2 ingrédients maintenant
      expect(recette.ingredients.length, 2);
      expect(recette.ingredients.last.name, 'Sel'); // Le dernier ingrédient doit être le sel
    });
  });

  // --- GROUPE 2 : Tests sur les parties du repas (Enum MealPart) ---
  group('Test des Enumérations (MealPart)', () {
    
    test('Les labels des parties du repas n\'ont pas été altérés', () {
      // Si un jour tu modifies par erreur "Plat principal" en "Plat prncipal",
      // ce test échouera et te préviendra que l'affichage de ton interface va être cassé !
      expect(MealPart.entree.label, 'Entrée');
      expect(MealPart.plat.label, 'Plat principal');
      expect(MealPart.dessert.label, 'Dessert');
    });

  });
}