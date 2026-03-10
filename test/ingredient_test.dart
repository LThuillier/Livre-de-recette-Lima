import 'package:flutter_test/flutter_test.dart';

// On importe le fichier que l'on veut tester. 
// Remplace 'livre_de_recettes' par le vrai nom de ton projet si besoin,
// ou utilise le chemin relatif : import '../lib/models/ingredient.dart';
import '../lib/models/ingredient.dart';

void main() {
  // La fonction group() permet de ranger ensemble plusieurs tests qui concernent le même sujet.
  group('Test de la classe Ingredient et de son affichage (toString)', () {
    
    // Test n°1 : Un ingrédient classique avec une unité (ex: grammes)
    test('Affiche correctement une quantité entière avec unité (ex: g)', () {
      // 1. ARRANGEMENT (On prépare nos données)
      final farine = Ingredient(name: 'Farine', quantity: 200, unit: 'g');

      // 2. ACTION (On appelle la fonction qu'on veut tester)
      final resultat = farine.toString();

      // 3. ASSERTION (On vérifie que le résultat est exactement ce qu'on attend)
      expect(resultat, '200 g de Farine');
    });

    // Test n°2 : Un ingrédient sans unité (ex: une pomme entière)
    test('Affiche correctement une quantité sans unité (sans le "de")', () {
      final pomme = Ingredient(name: 'Pommes', quantity: 3, unit: '');
      
      final resultat = pomme.toString();

      // Ici, on vérifie que le code n'affiche pas "3 de Pommes"
      expect(resultat, '3 Pommes');
    });

    // Test n°3 : Un ingrédient avec un chiffre à virgule
    test('Affiche correctement un chiffre à virgule (double)', () {
      final lait = Ingredient(name: 'Lait', quantity: 1.5, unit: 'L');
      
      final resultat = lait.toString();

      // Le code doit garder le ".5"
      expect(resultat, '1.5 L de Lait');
    });

  });
}