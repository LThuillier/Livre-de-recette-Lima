# Livre de recettes - Projet BTS SIO

Application Flutter de gestion de recettes avec planning hebdomadaire, edition en direct et stockage Supabase.

## Objectif du README
Ce document donne a l examinateur toutes les etapes pour lancer et verifier le projet rapidement.

## Lancement rapide
```bash
flutter pub get
flutter run -d chrome
```

Pour Windows (PowerShell), si `flutter` n est pas dans le PATH:
```powershell
& "C:\src\flutter\bin\flutter.bat" pub get
& "C:\src\flutter\bin\flutter.bat" run -d chrome
```

Autres cibles possibles:
```bash
flutter run -d windows
flutter run -d android
```

Ce que fait l application au demarrage:
- initialise Supabase (`recipes`, `ingredients`, bucket `recettes`)
- charge les recettes et leurs ingredients
- recupere le planning hebdomadaire depuis `SharedPreferences`
- regenere automatiquement un nouveau planning si l ancien a plus de 7 jours

## URLs utiles (mode web)
- URL locale affichee dans le terminal Flutter au lancement (exemple: `http://localhost:xxxxx`)

## Comptes de demonstration
- Aucun compte requis pour la demonstration actuelle (pas d ecran de connexion).

## Donnees de demonstration
- Les donnees proviennent de Supabase (pas de seed locale incluse dans ce depot).
- Si la base est vide, ajouter une recette depuis le bouton `+` de l application.

Structure de donnees attendue:
- table `recipes` (id, title, category, label, part, image_url, description, created_at)
- table `ingredients` (recipe_id, name, quantity, unit)
- bucket storage `recettes` pour les images

## Parcours de verification conseille (5 a 10 min)
1. Ouvrir l application et verifier l affichage de la grille des recettes.
2. Utiliser la navigation gauche pour filtrer par categorie (`Sale-Viandes`, `Sale-Poisson`, `Sale-Veggie`, `Sucre`).
3. Cliquer sur la loupe et verifier la recherche par titre.
4. Ajouter une recette avec `+`, selectionner categorie/partie du repas et importer une image.
5. Ouvrir une recette: modifier le titre, la description, la categorie, la partie du repas et la liste des ingredients.
6. Verifier la sauvegarde automatique (edition en direct avec debounce) en revenant a l index.
7. Ouvrir `PLANNING DE LA SEMAINE`, regenerer la semaine, puis regenerer un repas ou un plat precis.
8. Relancer l application et verifier que le planning de la semaine est conserve (SharedPreferences).
9. Basculer le theme clair/sombre puis supprimer une recette depuis l ecran detail.

## Tests automatiques
```bash
flutter test
```

Tests presents:
- `test/ingredient_test.dart`: TDD sur `Ingredient.toString()`
- `test/recipe_test.dart`: valeurs par defaut Recipe + enum `MealPart`

## Lecture de documents DOCX
Un lecteur DOCX est disponible dans l'application via l'icone `document` de la barre du haut.

Fonctionnement:
- selection d'un fichier `.docx`
- extraction du texte depuis le document Word
- affichage du contenu en lecture dans un ecran dedie

## Documentation API (equivalent phpdoc en Dart)
Le projet etant en Flutter/Dart, l'equivalent de `phpdoc` est `dartdoc`.

Generation de la documentation:
```powershell
powershell -ExecutionPolicy Bypass -File .\tool\generate_api_docs.ps1
```

Sortie generee:
- `docs/api/index.html`

## Points techniques a presenter a l oral
- CRUD recettes via Supabase (controller dedie)
- gestion des ingredients lies a une recette
- upload image vers Supabase Storage
- editeur detail type "Notion" avec sauvegarde asynchrone
- planning hebdomadaire auto-genere et persistant 7 jours
- interface responsive (mobile/desktop) + theme clair/sombre

## Fichiers importants
- `lib/main.dart`
- `lib/controllers/recipe_controller.dart`
- `lib/models/recipe.dart`
- `lib/models/ingredient.dart`
- `test/ingredient_test.dart`
- `test/recipe_test.dart`

## Documentation complementaire
- Diagramme de classe (Markdown): `diagrammedeclasse.md`
- Diagramme de sequence (Markdown): `diagramme_de_sequences.md`
- UML use case (PlantUML): `utilisation.puml`
- UML classe (PlantUML): `diagram.puml`
- UML sequence (PlantUML): `sequence.puml`
- Dossier projet E5: `Dossier E5 Flutter.docx`
- Document planning: `Plannificateur de recette.docx`
