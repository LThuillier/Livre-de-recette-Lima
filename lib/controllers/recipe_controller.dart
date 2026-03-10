import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:async'; // Pour le Timer de sauvegarde intelligente
import '../models/recipe.dart';
import '../models/ingredient.dart';

class RecipeController {
  // Instance de la base de données Supabase
  final _supabase = Supabase.instance.client;
  
  // Liste locale vide au démarrage
  List<Recipe> _recipes = [];

  List<Recipe> get all => _recipes;

  // 1. LIRE : Télécharger les recettes depuis Supabase
  Future<void> fetchRecipes() async {
    try {
      // On demande les recettes ET leurs ingrédients imbriqués grâce aux clés étrangères
      final data = await _supabase.from('recipes').select('*, ingredients(*)').order('created_at', ascending: false);
      
      _recipes = data.map((json) {
        // Reconstruire la liste d'ingrédients
        var ingredientsJson = json['ingredients'] as List<dynamic>? ?? [];
        List<Ingredient> ingredientsList = ingredientsJson.map((ing) => Ingredient(
          name: ing['name'],
          quantity: (ing['quantity'] as num).toDouble(),
          unit: ing['unit'] ?? '',
        )).toList();

        // Retrouver la bonne enum de la partie du repas
        MealPart part = MealPart.plat;
        try {
          part = MealPart.values.firstWhere((e) => e.name == json['part']);
        } catch (_) {}

        return Recipe(
          id: json['id'], // C'est maintenant le vrai UUID de Supabase !
          title: json['title'],
          category: json['category'],
          label: json['label'] ?? '',
          part: part,
          imageUrl: json['image_url'] ?? 'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=500',
          description: json['description'] ?? '',
          ingredients: ingredientsList,
          createdAt: DateTime.parse(json['created_at']),
          owner: json['owner'] ?? 'Matéo Esteban',
        );
      }).toList();
    } catch (e) {
      print("Erreur lors de la récupération : $e");
    }
  }

  // 2. CRÉER : Ajouter une nouvelle recette
  Future<void> store(Recipe r) async {
    try {
      // Insertion dans la base et récupération de la réponse (pour avoir l'ID)
      final response = await _supabase.from('recipes').insert({
        'title': r.title,
        'category': r.category,
        'label': r.label,
        'part': r.part.name,
        'image_url': r.imageUrl,
        'description': r.description,
        'owner': r.owner,
      }).select().single();

      // On met à jour l'ID de notre recette locale avec l'UUID de la base
      r.id = response['id'];
      _recipes.insert(0, r); 
    } catch (e) {
      print("Erreur lors de la création : $e");
    }
  }

  // Timer pour la sauvegarde intelligente (Debounce)
  Timer? _debounce;

  // 3. METTRE À JOUR : Éditeur style Notion
  Future<void> update(String id, {String? title, String? desc, String? cat, MealPart? part, String? imageUrl}) async {
    // A. Mise à jour IMMÉDIATE de l'affichage local (pour une expérience fluide)
    int index = _recipes.indexWhere((r) => r.id == id);
    if (index == -1) return;
    
    if (title != null) _recipes[index].title = title;
    if (desc != null) _recipes[index].description = desc;
    if (cat != null) _recipes[index].category = cat;
    if (part != null) _recipes[index].part = part;
    if (imageUrl != null) _recipes[index].imageUrl = imageUrl; // Mise à jour locale de l'image

    Recipe currentRecipe = _recipes[index];

    // B. Sauvegarde asynchrone sur internet (attend 1 seconde après la dernière modification)
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      try {
        // Mise à jour de la table "recipes"
        await _supabase.from('recipes').update({
          'title': currentRecipe.title,
          'description': currentRecipe.description,
          'category': currentRecipe.category,
          'part': currentRecipe.part.name,
          'image_url': currentRecipe.imageUrl, // Mise à jour de l'image dans Supabase
        }).eq('id', id);

        // Synchronisation des "ingredients" (on supprime les anciens et on insère la nouvelle liste)
        await _supabase.from('ingredients').delete().eq('recipe_id', id);
        
        if (currentRecipe.ingredients.isNotEmpty) {
          final ingData = currentRecipe.ingredients.map((ing) => {
            'recipe_id': id,
            'name': ing.name,
            'quantity': ing.quantity,
            'unit': ing.unit,
          }).toList();
          
          await _supabase.from('ingredients').insert(ingData);
        }
      } catch (e) {
        print("Erreur lors de la mise à jour : $e");
      }
    });
  }

  // 4. SUPPRIMER : Effacer une recette
  Future<void> destroy(String id) async {
    try {
      await _supabase.from('recipes').delete().eq('id', id);
      _recipes.removeWhere((r) => r.id == id);
    } catch (e) {
      print("Erreur lors de la suppression : $e");
    }
  }

  // === PLANNING HEBDOMADAIRE ===
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