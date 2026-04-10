import 'package:flutter/material.dart';

/// Represente la partie d'un repas utilisee pour classer les recettes.
enum MealPart {
  entree('Entrée', Icons.flatware),
  plat('Plat principal', Icons.restaurant),
  dessert('Dessert', Icons.cake);

  /// Libelle affiche dans l'interface.
  final String label;

  /// Icone associee a la partie du repas.
  final IconData icon;

  const MealPart(this.label, this.icon);
}

/// Modele d'un ingredient d'une recette.
class Ingredient {
  /// Nom de l'ingredient.
  String name;

  /// Quantite de l'ingredient.
  double quantity;

  /// Unite de mesure (g, ml, c. a soupe, etc.).
  String unit;

  /// Construit un ingredient complet.
  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  /// Retourne une representation lisible de l'ingredient pour l'UI.
  @override
  String toString() {
    final qStr = quantity > 0
        ? (quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString())
        : '';
    final uStr = unit.isNotEmpty ? ' $unit' : '';
    final prep = unit.isNotEmpty ? ' de ' : (qStr.isNotEmpty ? ' ' : '');
    return '$qStr$uStr$prep$name'.trim();
  }
}
