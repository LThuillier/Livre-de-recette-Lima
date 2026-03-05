import 'package:flutter/material.dart';
import 'dart:math';
import '../models/recipe.dart';
import '../models/ingredient.dart';


class RecipeController {
  final List<Recipe> _recipes = [
    Recipe(
      id: '1', 
      title: 'Tartelettes Chocolat Caramel Praliné', 
      category: 'Sucré', 
      label: 'Favoris', 
      part: MealPart.dessert,
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500',
      description: 'Tartelettes gourmandes à souhait !!! \n\n♡Pâte sablée noisette, praliné noisette, ganache chocolat au lait, caramel et éclats de noisette♡\n\n☆Recette pour 6 tartelettes de 8.5cm☆',
      ingredients: [
        Ingredient(name: 'Farine', quantity: 260, unit: 'g'),
        Ingredient(name: 'Beurre mou', quantity: 130, unit: 'g'),
        Ingredient(name: 'Sucre glace', quantity: 90, unit: 'g'),
        Ingredient(name: 'Poudre de noisette', quantity: 30, unit: 'g'),
        Ingredient(name: 'Oeuf', quantity: 1, unit: 'pièce'),
      ],
      createdAt: DateTime.now(),
    ),
    Recipe(
      id: '2', 
      title: 'Sardines Grillées au Citron', 
      category: 'Salé-Poisson', 
      label: 'Budget +++', 
      part: MealPart.plat,
      imageUrl: 'https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=500',
      description: 'Une recette simple et efficace pour l\'été. Idéal au barbecue.',
      ingredients: [
        Ingredient(name: 'Sardines', quantity: 12, unit: 'pièces'),
        Ingredient(name: 'Citrons', quantity: 2, unit: 'pièces'),
      ],
      createdAt: DateTime.now(),
    ),
  ];

  List<Recipe> get all => _recipes;

  void store(Recipe r) => _recipes.insert(0, r);

  void update(String id, {String? title, String? desc, String? cat, MealPart? part}) {
    int index = _recipes.indexWhere((r) => r.id == id);
    if (index != -1) {
      if (title != null) _recipes[index].title = title;
      if (desc != null) _recipes[index].description = desc;
      if (cat != null) _recipes[index].category = cat;
      if (part != null) _recipes[index].part = part;
    }
  }

  void destroy(String id) => _recipes.removeWhere((r) => r.id == id);

  Map<String, Map<String, List<Recipe>>> generateWeeklyPlan() {
    final days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    Map<String, Map<String, List<Recipe>>> plan = {};
    for (var day in days) {
      plan[day] = {"Midi": _getRandomFullMeal(), "Soir": _getRandomFullMeal()};
    }
    return plan;
  }

  List<Recipe> _getRandomFullMeal() {
    final entrees = _recipes.where((r) => r.part == MealPart.entree).toList();
    final plats = _recipes.where((r) => r.part == MealPart.plat).toList();
    final desserts = _recipes.where((r) => r.part == MealPart.dessert).toList();
    Recipe fallback = _recipes.isNotEmpty ? _recipes[0] : Recipe(id: '0', title: 'Vide', category: '', label: '', imageUrl: '', createdAt: DateTime.now(), ingredients: []);
    return [
      entrees.isNotEmpty ? entrees[Random().nextInt(entrees.length)] : fallback,
      plats.isNotEmpty ? plats[Random().nextInt(plats.length)] : fallback,
      desserts.isNotEmpty ? desserts[Random().nextInt(desserts.length)] : fallback,
    ];
  }
}