import '../models/ingredient.dart';

/// Modele principal d'une recette manipulee par l'application.
class Recipe {
  /// Identifiant unique de la recette (UUID Supabase).
  String id;

  /// Titre de la recette.
  String title;

  /// Categorie fonctionnelle (sale, sucre, etc.).
  String category;

  /// Etiquette libre de la recette.
  String label;

  /// URL d'image de la recette.
  String imageUrl;

  /// Description detaillee de la recette.
  String description;

  /// Liste des ingredients associes.
  List<Ingredient> ingredients;

  /// Date de creation en base.
  DateTime createdAt;

  /// Partie du repas correspondante.
  MealPart part;

  /// Construit une recette complete.
  Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.label,
    required this.imageUrl,
    this.description = '',
    required this.ingredients,
    required this.createdAt,
    this.part = MealPart.plat,
  });
}
