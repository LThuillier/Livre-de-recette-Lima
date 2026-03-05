import 'package:flutter/material.dart';
import 'dart:math';
import '../models/recipe.dart';

enum MealPart {
  entree("Entrée", Icons.flatware),
  plat("Plat principal", Icons.restaurant),
  dessert("Dessert", Icons.cake);

  final String label;
  final IconData icon;
  const MealPart(this.label, this.icon);
}

class Ingredient {
  String name;
  double quantity;
  String unit;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  @override
  String toString() {
    String qStr = quantity > 0 ? (quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString()) : "";
    String uStr = unit.isNotEmpty ? " $unit" : "";
    String prep = unit.isNotEmpty ? " de " : (qStr.isNotEmpty ? " " : "");
    return "$qStr$uStr$prep$name".trim();
  }
}