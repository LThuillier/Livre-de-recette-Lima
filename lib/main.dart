import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:convert'; // Ajouté pour encoder le planning
import 'dart:io'; // Ajouté pour gérer le fichier image
import 'package:image_picker/image_picker.dart'; // Ajouté pour la galerie photo
import 'package:shared_preferences/shared_preferences.dart'; // Ajouté pour sauvegarder localement
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../controllers/recipe_controller.dart'; 

// Variable globale pour gérer le thème (Clair / Sombre)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sbacvmiavmoekrkupgme.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNiYWN2bWlhdm1vZWtya3VwZ21lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4Nzk3MzQsImV4cCI6MjA4ODQ1NTczNH0.rm-fW7ESdS-QO78AC0NAWpPtVqWAyyauVuHwIebIbtw',
  );

  runApp(const CuisineProApp());
}

class CuisineProApp extends StatelessWidget {
  const CuisineProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // --- THÈME CLAIR (Pastel) ---
          theme: ThemeData(
            brightness: Brightness.light, 
            scaffoldBackgroundColor: const Color(0xFFFFF5F7), 
            primaryColor: Colors.teal, 
            cardColor: Colors.white, 
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          // --- THÈME SOMBRE (Original) ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            primaryColor: Colors.tealAccent,
            cardColor: const Color(0xFF1A1A1A),
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          home: const RecipeIndexPage(),
        );
      }
    );
  }
}

class RecipeIndexPage extends StatefulWidget {
  const RecipeIndexPage({super.key});

  @override
  State<RecipeIndexPage> createState() => _RecipeIndexPageState();
}

class _RecipeIndexPageState extends State<RecipeIndexPage> {
  final RecipeController _controller = RecipeController();
  String _filterCategory = 'Tous';
  final List<String> categories = ['Tous', 'Salé-Viandes', 'Salé-Poisson', 'Salé-Veggie', 'Sucré'];
  
  bool _isLoading = true;

  // --- VARIABLES POUR LE PLANNING PERSISTANT ---
  Map<String, Map<String, List<Recipe>>>? _weeklyPlan;
  DateTime? _planDate;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    await _controller.fetchRecipes();
    await _initOrGetPlan(); // On charge le planning après avoir récupéré les recettes
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- LOGIQUE DE SAUVEGARDE DU PLANNING ---
  Future<void> _initOrGetPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planDateStr = prefs.getString('planDate');
    final planDataStr = prefs.getString('weeklyPlan');

    if (planDateStr != null && planDataStr != null) {
      _planDate = DateTime.parse(planDateStr);
      // Garde le plan si ça fait moins de 7 jours
      if (DateTime.now().difference(_planDate!).inDays < 7) {
        try {
          final decoded = jsonDecode(planDataStr) as Map<String, dynamic>;
          _weeklyPlan = _reconstructPlanFromJson(decoded);
          return; // Plan chargé avec succès
        } catch (e) {
          debugPrint("Erreur lors de la lecture du plan sauvegardé: $e");
        }
      }
    }
    
    // Si on arrive ici, le plan a plus de 7 jours (ou n'existe pas), on en génère un nouveau
    _weeklyPlan = _generatePlan();
    _planDate = DateTime.now();
    await _savePlanToPrefs();
  }

  // Permet de reconstruire les objets "Recipe" à partir des IDs sauvegardés
  Map<String, Map<String, List<Recipe>>> _reconstructPlanFromJson(Map<String, dynamic> json) {
    Map<String, Map<String, List<Recipe>>> plan = {};
    final days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    for (var day in days) {
      plan[day] = {
        "Midi": _getRecipesFromIds(List<String>.from(json[day]?["Midi"] ?? [])),
        "Soir": _getRecipesFromIds(List<String>.from(json[day]?["Soir"] ?? [])),
      };
    }
    return plan;
  }

  List<Recipe> _getRecipesFromIds(List<String> ids) {
    List<Recipe> result = [];
    for (int i = 0; i < 3; i++) {
      if (i < ids.length) {
        try {
          final r = _controller.all.firstWhere((recipe) => recipe.id == ids[i]);
          result.add(r);
          continue;
        } catch (_) {}
      }
      // Fallback au cas où une recette a été supprimée de la base entre temps
      MealPart part = i == 0 ? MealPart.entree : (i == 1 ? MealPart.plat : MealPart.dessert);
      final candidates = _controller.all.where((r) => r.part == part).toList();
      Recipe fallback = candidates.isNotEmpty 
          ? candidates[Random().nextInt(candidates.length)] 
          : (_controller.all.isNotEmpty ? _controller.all.first : Recipe(id: '0', title: 'Aucune recette', category: '', label: '', imageUrl: 'assets/pictures/default.png', createdAt: DateTime.now(), ingredients: []));
      result.add(fallback);
    }
    return result;
  }

  // Sauvegarde le plan dans le téléphone
  Future<void> _savePlanToPrefs() async {
    if (_weeklyPlan == null || _planDate == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('planDate', _planDate!.toIso8601String());

    Map<String, dynamic> jsonPlan = {};
    for (var day in _weeklyPlan!.keys) {
      jsonPlan[day] = {
        "Midi": _weeklyPlan![day]!["Midi"]!.map((r) => r.id).toList(),
        "Soir": _weeklyPlan![day]!["Soir"]!.map((r) => r.id).toList(),
      };
    }
    await prefs.setString('weeklyPlan', jsonEncode(jsonPlan));
  }

  Map<String, Map<String, List<Recipe>>> _generatePlan() {
    final days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    Map<String, Map<String, List<Recipe>>> plan = {};
    for (var day in days) {
      plan[day] = {"Midi": _getRandomFullMeal(), "Soir": _getRandomFullMeal()};
    }
    return plan;
  }

  List<Recipe> _getRandomFullMeal() {
    final entrees = _controller.all.where((r) => r.part == MealPart.entree).toList();
    final plats = _controller.all.where((r) => r.part == MealPart.plat).toList();
    final desserts = _controller.all.where((r) => r.part == MealPart.dessert).toList();
    Recipe fallback = _controller.all.isNotEmpty ? _controller.all.first : Recipe(id: '0', title: 'Aucune recette', category: '', label: '', imageUrl: 'assets/pictures/default.png', createdAt: DateTime.now(), ingredients: []);
    
    return [
      entrees.isNotEmpty ? entrees[Random().nextInt(entrees.length)] : fallback,
      plats.isNotEmpty ? plats[Random().nextInt(plats.length)] : fallback,
      desserts.isNotEmpty ? desserts[Random().nextInt(desserts.length)] : fallback,
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    Color tealColor = isLight ? Colors.teal : Colors.tealAccent;
    Color textColor = isLight ? Colors.black87 : Colors.white;
    Color bgAppBarColor = isLight ? const Color(0xFFFFF5F7) : const Color(0xFF0F0F0F);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 850 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));

        final filteredList = _filterCategory == 'Tous' 
            ? _controller.all 
            : _controller.all.where((r) => r.category == _filterCategory).toList();

        return Scaffold(
          drawer: isMobile ? Drawer(child: _buildSidebar(isMobile: true, isLight: isLight)) : null,
          appBar: AppBar(
            backgroundColor: bgAppBarColor,
            iconTheme: IconThemeData(color: textColor),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("LES RECETTES DE LIMA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor)),
                const SizedBox(width: 8),
              ],
            ),
            elevation: 0,
            actions: [
              // BOUTON RECHERCHE
              IconButton(
                onPressed: () {
                  showSearch(context: context, delegate: RecipeSearchDelegate(_controller.all, _controller));
                }, 
                icon: Icon(Icons.search, color: tealColor, size: 26),
                tooltip: "Chercher une recette",
              ),
              // BOUTON AJOUTER
              IconButton(
                onPressed: () => _showFormDialog(isLight), 
                icon: Icon(Icons.add_circle_outline, color: tealColor, size: 28),
                tooltip: "Ajouter une recette",
              ),
              // BOUTON CHANGEMENT DE THÈME (Déplacé tout à droite)
              IconButton(
                onPressed: () {
                  themeNotifier.value = isLight ? ThemeMode.dark : ThemeMode.light;
                }, 
                icon: Icon(isLight ? Icons.dark_mode : Icons.light_mode, color: tealColor, size: 24),
                tooltip: isLight ? "Passer au thème sombre" : "Passer au thème clair",
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(isMobile: false, isLight: isLight),
              Expanded(
                child: Stack(
                  children: [
                    _isLoading 
                      ? Center(child: CircularProgressIndicator(color: tealColor))
                      : GridView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: isMobile ? 1.0 : 0.8,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) => _recipeCard(filteredList[index], isLight),
                        ),
                    
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent, // Toujours vif pour attirer l'oeil
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 5,
                          ),
                          onPressed: () => _showPlanner(isLight),
                          icon: const Icon(Icons.calendar_month),
                          label: const Text("PLANNING DE LA SEMAINE", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool isMobile, required bool isLight}) {
    return Container(
      width: isMobile ? double.infinity : 240,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.black,
        border: isMobile ? null : Border(right: BorderSide(color: isLight ? Colors.pink.shade50 : const Color(0xFF222222))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text("NAVIGATION", style: TextStyle(color: isLight ? Colors.pink.shade200 : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            Expanded(
              child: ListView(
                children: categories.map((cat) => ListTile(
                  title: Text(cat, style: TextStyle(fontSize: 14, fontWeight: _filterCategory == cat ? FontWeight.bold : FontWeight.normal, color: _filterCategory == cat ? (isLight ? Colors.teal : Colors.tealAccent) : (isLight ? Colors.black87 : Colors.white60))),
                  leading: Icon(Icons.folder_open, size: 18, color: _filterCategory == cat ? (isLight ? Colors.teal : Colors.tealAccent) : (isLight ? Colors.grey[400] : Colors.grey[700])),
                  onTap: () {
                    setState(() => _filterCategory = cat);
                    if (isMobile) {
                      Navigator.pop(context);
                    }
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recipeCard(Recipe recipe, bool isLight) {
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe, controller: _controller)));
        setState(() {}); 
      },
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLight ? Colors.pink.shade50 : const Color(0xFF2A2A2A)),
          boxShadow: isLight ? [
            BoxShadow(
              color: Colors.pink.shade100.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: recipe.imageUrl.startsWith('http')
                  ? Image.network(recipe.imageUrl, fit: BoxFit.cover, width: double.infinity)
                  : Image.asset(
                      recipe.imageUrl, 
                      fit: BoxFit.cover, 
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isLight ? Colors.pink.shade50 : Colors.grey[800], 
                        child: Icon(Icons.image_not_supported, color: isLight ? Colors.pink.shade200 : Colors.white54, size: 40)
                      ),
                    ),
            )),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isLight ? Colors.black87 : Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(recipe.part.label, style: TextStyle(color: isLight ? Colors.teal : Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormDialog(bool isLight) {
    final titleController = TextEditingController();
    
    MealPart selectedPart = MealPart.plat;
    String selectedCat = categories[1];
    
    // Variables pour l'upload d'image
    String? uploadedImageUrl;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      barrierDismissible: !isUploadingImage, // Empêche de fermer pendant l'upload
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isLight ? Colors.white : const Color(0xFF151515), 
          title: Text("Nouvelle Recette", style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController, 
                  style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  decoration: const InputDecoration(labelText: "Titre", border: UnderlineInputBorder())
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  dropdownColor: isLight ? Colors.white : const Color(0xFF1A1A1A),
                  style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  items: categories.where((c) => c != 'Tous').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCat = v!),
                  decoration: const InputDecoration(labelText: "Catégorie"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<MealPart>(
                  value: selectedPart,
                  dropdownColor: isLight ? Colors.white : const Color(0xFF1A1A1A),
                  style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  items: MealPart.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPart = v!),
                  decoration: const InputDecoration(labelText: "Partie du repas"),
                ),
                const SizedBox(height: 25),
                
                // --- BOUTON DE GALERIE REMPLACE LE TEXTE ---
                if (isUploadingImage)
                  const CircularProgressIndicator(color: Colors.teal)
                else
                  Column(
                    children: [
                      if (uploadedImageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(uploadedImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLight ? Colors.teal : Colors.tealAccent,
                          foregroundColor: isLight ? Colors.white : Colors.black,
                        ),
                        onPressed: () async {
                          final picker = ImagePicker();
                          // Ouvre la galerie du téléphone/PC
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile == null) return; // Si on annule

                          setDialogState(() => isUploadingImage = true);

                          try {
                            final file = File(pickedFile.path);
                            final fileExt = pickedFile.path.split('.').last;
                            // Créé un nom unique basé sur l'heure pour ne pas écraser d'autres images
                            final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                            // Envoie dans Supabase Storage ("recettes")
                            await Supabase.instance.client.storage
                                .from('recettes')
                                .upload(fileName, file);

                            // Récupère l'URL publique générée par Supabase
                            final publicUrl = Supabase.instance.client.storage
                                .from('recettes')
                                .getPublicUrl(fileName);

                            setDialogState(() {
                              uploadedImageUrl = publicUrl;
                              isUploadingImage = false;
                            });
                          } catch (e) {
                            setDialogState(() => isUploadingImage = false);
                            debugPrint("Erreur lors de l'upload: $e");
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(uploadedImageUrl == null ? "Ajouter une photo" : "Changer la photo"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploadingImage ? null : () => Navigator.pop(context), 
              child: Text("Annuler", style: TextStyle(color: isLight ? Colors.grey : Colors.white70))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
              onPressed: isUploadingImage ? null : () async {
                if(titleController.text.isNotEmpty) {
                  await _controller.store(Recipe(
                    id: DateTime.now().toString(),
                    title: titleController.text,
                    category: selectedCat,
                    label: 'Nouveau',
                    part: selectedPart,
                    // Si on a uploadé, on prend l'URL de Supabase, sinon image par défaut !
                    imageUrl: uploadedImageUrl ?? 'assets/pictures/pancake.png', 
                    createdAt: DateTime.now(),
                    ingredients: [],
                  ));
                  setState(() {});
                  if (context.mounted) Navigator.pop(context); 
                }
              },
              child: const Text("VALIDER"),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanner(bool isLight) { 
    showModalBottomSheet( 
      context: context, 
      isScrollControlled: true,
      useSafeArea: true, 
      backgroundColor: isLight ? Colors.white : const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), 
      builder: (context) => StatefulBuilder( 
        builder: (BuildContext context, StateSetter setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("PLANNING HEBDOMADAIRE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isLight ? Colors.teal : Colors.tealAccent)),
                      IconButton(
                        icon: Icon(Icons.refresh, color: isLight ? Colors.teal : Colors.tealAccent),
                        tooltip: "Générer une nouvelle semaine",
                        onPressed: () {
                          setState(() {
                            _weeklyPlan = _generatePlan();
                            _planDate = DateTime.now();
                          });
                          _savePlanToPrefs(); // On sauvegarde
                          setSheetState(() {});
                        },
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    // PADDING REDUIT ICI : bottom à 30 au lieu de 60
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
                    children: _weeklyPlan!.keys.map((day) => _buildDayPlan(day, _weeklyPlan![day]!, setSheetState, isLight)).toList(),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildDayPlan(String day, Map<String, List<Recipe>> meals, StateSetter setSheetState, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(day, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isLight ? Colors.teal : Colors.tealAccent)), 
        Divider(color: isLight ? Colors.pink.shade50 : Colors.white12),
        _buildMealSection(day, "Midi", meals["Midi"]!, setSheetState, isLight),
        _buildMealSection(day, "Soir", meals["Soir"]!, setSheetState, isLight),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMealSection(String day, String mealTime, List<Recipe> recipes, StateSetter setSheetState, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Text(mealTime.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _weeklyPlan![day]![mealTime] = _getRandomFullMeal();
                  });
                  _savePlanToPrefs(); // On sauvegarde
                  setSheetState(() {}); 
                },
                child: Icon(Icons.autorenew, size: 16, color: isLight ? Colors.teal : Colors.tealAccent),
              )
            ],
          ),
          const SizedBox(height: 5), 
          _buildDishRow(day, mealTime, 0, "🥗", recipes[0], setSheetState, isLight),
          _buildDishRow(day, mealTime, 1, "🍖", recipes[1], setSheetState, isLight),
          _buildDishRow(day, mealTime, 2, "🍰", recipes[2], setSheetState, isLight),
        ], 
      ),
    );
  }

  Widget _buildDishRow(String day, String mealTime, int dishIndex, String emoji, Recipe recipe, StateSetter setSheetState, bool isLight) {
    return Row(
      children: [
        Expanded(
          // InkWell REND LA RECETTE CLIQUABLE DANS LE PLANNING
          child: InkWell(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe, controller: _controller)));
              setState(() {}); 
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), 
              child: Text("$emoji ${recipe.title}", style: TextStyle(fontSize: 14, color: isLight ? Colors.black87 : Colors.white), overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.sync, size: 18, color: isLight ? Colors.black45 : Colors.white54),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: "Changer ce plat",
          onPressed: () {
            final allRecipes = _controller.all;
            MealPart targetPart = dishIndex == 0 ? MealPart.entree : (dishIndex == 1 ? MealPart.plat : MealPart.dessert);
            final candidates = allRecipes.where((r) => r.part == targetPart).toList();
            
            if (candidates.isNotEmpty) {
              setState(() {
                _weeklyPlan![day]![mealTime]![dishIndex] = candidates[Random().nextInt(candidates.length)];
              });
              _savePlanToPrefs(); // On sauvegarde
              setSheetState(() {});
            }
          },
        ),
      ],
    );
  }
}

// =============================================================================
// RECHERCHE : DÉLÉGUÉ DE RECHERCHE POUR LE BOUTON LOUPE
// =============================================================================

class RecipeSearchDelegate extends SearchDelegate<Recipe?> {
  final List<Recipe> recipes;
  final RecipeController controller;

  RecipeSearchDelegate(this.recipes, this.controller);

  @override
  String get searchFieldLabel => "Chercher une recette...";

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    final results = recipes.where((r) => r.title.toLowerCase().contains(query.toLowerCase())).toList();
    
    return Container(
      color: isLight ? const Color(0xFFFFF5F7) : const Color(0xFF0F0F0F),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final r = results[index];
          return ListTile(
            leading: Icon(Icons.restaurant, color: isLight ? Colors.teal : Colors.tealAccent),
            title: Text(r.title, style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
            subtitle: Text(r.category, style: TextStyle(color: isLight ? Colors.black54 : Colors.white54)),
            onTap: () async {
              close(context, null);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: r, controller: controller)));
            },
          );
        },
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    bool isLight = theme.brightness == Brightness.light;
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: isLight ? const Color(0xFFFFF5F7) : const Color(0xFF0F0F0F),
        iconTheme: IconThemeData(color: isLight ? Colors.black87 : Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }
}

// =============================================================================
// VUE DÉTAIL : ÉDITEUR DIRECT STYLE NOTION (S'ADAPTE AU THÈME)
// =============================================================================

class _IngredientControllers {
  TextEditingController qty;
  TextEditingController unit;
  TextEditingController name;
  _IngredientControllers({required this.qty, required this.unit, required this.name});
}

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  final RecipeController controller;
  const RecipeDetailPage({super.key, required this.recipe, required this.controller});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final List<_IngredientControllers> _ingControllers = [];
  
  final List<String> editCategories = ['Salé-Viandes', 'Salé-Poisson', 'Salé-Veggie', 'Sucré'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descController = TextEditingController(text: widget.recipe.description);
    
    for (var ing in widget.recipe.ingredients) {
      _ingControllers.add(_IngredientControllers(
        qty: TextEditingController(text: (ing.quantity % 1 == 0 ? ing.quantity.toInt() : ing.quantity).toString()),
        unit: TextEditingController(text: ing.unit),
        name: TextEditingController(text: ing.name),
      ));
    }
  }

  void _syncData() {
    widget.controller.update(
      widget.recipe.id,
      title: _titleController.text,
      desc: _descController.text,
      part: widget.recipe.part,
      cat: widget.recipe.category,
      imageUrl: widget.recipe.imageUrl,
    );
  }

  void _showFullScreenImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer( 
              child: widget.recipe.imageUrl.startsWith('http')
                  ? Image.network(widget.recipe.imageUrl, fit: BoxFit.contain)
                  : Image.asset(widget.recipe.imageUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }

  // --- BOUTON DE GALERIE REMPLACE LE TEXTE AUSSI POUR L'EDITION ---
  void _showEditImageDialog(bool isLight) {
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isLight ? Colors.white : const Color(0xFF151515),
          title: Text("Modifier l'image", style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          content: isUploading 
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.tealAccent)))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.recipe.imageUrl.startsWith('http')
                        ? Image.network(widget.recipe.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover)
                        : Image.asset(widget.recipe.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox()),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight ? Colors.teal : Colors.tealAccent,
                      foregroundColor: isLight ? Colors.white : Colors.black,
                    ),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile == null) return;

                      setDialogState(() => isUploading = true);
                      try {
                        final file = File(pickedFile.path);
                        final fileExt = pickedFile.path.split('.').last;
                        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                        await Supabase.instance.client.storage
                            .from('recettes')
                            .upload(fileName, file);

                        final publicUrl = Supabase.instance.client.storage
                            .from('recettes')
                            .getPublicUrl(fileName);

                        // On met à jour l'image directement sans devoir valider avec un autre bouton
                        setState(() {
                          widget.recipe.imageUrl = publicUrl;
                        });
                        _syncData(); // Synchronise avec ta base de données
                        
                        if (context.mounted) Navigator.pop(context); // Ferme la boîte de dialogue une fois terminé
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        debugPrint("Erreur upload: $e");
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Choisir depuis la galerie"),
                  ),
                ],
              ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context), 
              child: Text("Annuler", style: TextStyle(color: isLight ? Colors.grey : Colors.white70))
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;
    bool isLight = Theme.of(context).brightness == Brightness.light;

    Color bgColor = isLight ? const Color(0xFFFFF5F7) : const Color(0xFF0F0F0F);
    Color textColor = isLight ? Colors.black87 : Colors.white;
    Color hintColor = isLight ? Colors.black26 : Colors.white24;
    Color tealColor = isLight ? Colors.teal : Colors.tealAccent;

    return Scaffold(
      backgroundColor: bgColor, 
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isMobile ? 250 : 500, 
            pinned: true,
            backgroundColor: bgColor,
            iconTheme: IconThemeData(color: isLight ? Colors.black87 : Colors.white),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar( 
              background: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector( 
                    onTap: _showFullScreenImage,
                    child: widget.recipe.imageUrl.startsWith('http')
                        ? Image.network(widget.recipe.imageUrl, fit: BoxFit.cover, width: double.infinity)
                        : Image.asset(
                            widget.recipe.imageUrl, 
                            fit: BoxFit.cover, 
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isLight ? Colors.pink.shade50 : Colors.grey[800], 
                              child: Center(child: Icon(Icons.image_not_supported, color: isLight ? Colors.pink.shade200 : Colors.white54, size: 60))
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.tealAccent),
                            tooltip: "Modifier l'image",
                            onPressed: () => _showEditImageDialog(isLight),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: "Supprimer la recette",
                            onPressed: () async {
                              await widget.controller.destroy(widget.recipe.id); 
                              if (context.mounted) Navigator.pop(context); 
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 32.0, vertical: isMobile ? 24.0 : 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.bold, letterSpacing: -1, color: textColor),
                    maxLines: null,
                    onChanged: (val) => _syncData(),
                    decoration: InputDecoration(hintText: "Titre de la recette", border: InputBorder.none, hintStyle: TextStyle(color: hintColor)),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _editableMealPartProperty(isLight),
                  _editableCategoryProperty(isLight),
                  _notionProperty(Icons.calendar_today_outlined, "Créé le", "${widget.recipe.createdAt.day}/${widget.recipe.createdAt.month}/${widget.recipe.createdAt.year}", isLight),
                  
                  Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Divider(color: isLight ? Colors.pink.shade100 : const Color(0xFF2A2A2A))),
                  
                  TextField(
                    controller: _descController,
                    maxLines: null,
                    onChanged: (val) => _syncData(),
                    style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
                    decoration: InputDecoration(border: InputBorder.none, hintText: "Commencez à écrire votre recette ici...", hintStyle: TextStyle(color: hintColor)),
                  ),
                  
                  const SizedBox(height: 40),
                  Text("Ingrédients", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tealColor)),
                  const SizedBox(height: 16),
                  
                  ...widget.recipe.ingredients.asMap().entries.map((entry) {
                    int index = entry.key;
                    Ingredient ing = entry.value;
                    var controllers = _ingControllers[index];
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isMobile) Icon(Icons.drag_indicator, size: 16, color: hintColor),
                          if (!isMobile) const SizedBox(width: 8),
                          const Icon(Icons.check_box_outline_blank, size: 18, color: Colors.grey),
                          const SizedBox(width: 12),
                          
                          SizedBox(
                            width: 45,
                            child: TextField(
                              controller: controllers.qty,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                ing.quantity = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                                widget.controller.update(widget.recipe.id); 
                              },
                              style: TextStyle(fontSize: 15, color: tealColor, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(hintText: "Qté", border: InputBorder.none, hintStyle: TextStyle(color: hintColor)),
                            ),
                          ),
                          
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: controllers.unit,
                              onChanged: (val) {
                                ing.unit = val;
                                widget.controller.update(widget.recipe.id);
                              },
                              style: TextStyle(fontSize: 15, color: isLight ? Colors.black54 : Colors.white70),
                              decoration: InputDecoration(hintText: "Unité", border: InputBorder.none, hintStyle: TextStyle(color: hintColor)),
                            ),
                          ),
                          
                          Expanded(
                            child: TextField(
                              controller: controllers.name,
                              onChanged: (val) {
                                ing.name = val;
                                widget.controller.update(widget.recipe.id);
                              },
                              style: TextStyle(fontSize: 15, color: textColor),
                              decoration: InputDecoration(hintText: "Nom de l'ingrédient", border: InputBorder.none, hintStyle: TextStyle(color: hintColor)),
                            ),
                          ),
                          
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: hintColor),
                            onPressed: () {
                              setState(() {
                                widget.recipe.ingredients.removeAt(index);
                                _ingControllers.removeAt(index);
                                widget.controller.update(widget.recipe.id);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  InkWell(
                    onTap: () {
                      setState(() {
                        widget.recipe.ingredients.add(Ingredient(name: "", quantity: 1, unit: ""));
                        _ingControllers.add(_IngredientControllers(
                          qty: TextEditingController(text: "1"),
                          unit: TextEditingController(text: ""),
                          name: TextEditingController(text: ""),
                        ));
                        widget.controller.update(widget.recipe.id);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: tealColor, size: 20),
                          const SizedBox(width: 8),
                          Text("Ajouter un ingrédient", style: TextStyle(color: tealColor, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notionProperty(IconData icon, String label, String value, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isLight ? Colors.grey[500] : Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: isLight ? Colors.grey[600] : Colors.grey[400], fontSize: 14))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isLight ? Colors.black87 : Colors.white))),
        ],
      ),
    );
  }

  Widget _editableMealPartProperty(bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 16, color: isLight ? Colors.grey[500] : Colors.grey[600]), 
          const SizedBox(width: 12), 
          SizedBox(width: 100, child: Text("Partie", style: TextStyle(color: isLight ? Colors.grey[600] : Colors.grey[400], fontSize: 14))), 
          Expanded( 
            child: DropdownButtonHideUnderline( 
              child: DropdownButton<MealPart>(
                value: widget.recipe.part,
                isDense: true,
                iconSize: 20,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isLight ? Colors.black87 : Colors.white),
                dropdownColor: isLight ? Colors.white : const Color(0xFF1A1A1A),
                items: MealPart.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (newPart) {
                  if (newPart != null) {
                    setState(() {
                      widget.recipe.part = newPart;
                    });
                    _syncData(); 
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableCategoryProperty(bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.folder_open_outlined, size: 16, color: isLight ? Colors.grey[500] : Colors.grey[600]), 
          const SizedBox(width: 12), 
          SizedBox(width: 100, child: Text("Catégorie", style: TextStyle(color: isLight ? Colors.grey[600] : Colors.grey[400], fontSize: 14))), 
          Expanded( 
            child: DropdownButtonHideUnderline( 
              child: DropdownButton<String>(
                value: editCategories.contains(widget.recipe.category) ? widget.recipe.category : editCategories.first,
                isDense: true,
                iconSize: 20,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isLight ? Colors.black87 : Colors.white),
                dropdownColor: isLight ? Colors.white : const Color(0xFF1A1A1A),
                items: editCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (newCat) {
                  if (newCat != null) {
                    setState(() {
                      widget.recipe.category = newCat;
                    });
                    _syncData(); 
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}