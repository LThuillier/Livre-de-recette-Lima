import 'package:flutter/material.dart';
import 'dart:math';
import '../models/ingredient.dart';

class Recipe {
  String id;
  String title;
  String category;
  String label;
  String imageUrl;
  String description;
  List<Ingredient> ingredients; 
  DateTime createdAt;
  String owner;
  MealPart part; 

  Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.label,
    required this.imageUrl,
    this.description = "",
    required this.ingredients, 
    required this.createdAt,
    this.owner = "Matéo Esteban",
    this.part = MealPart.plat,
  });
}