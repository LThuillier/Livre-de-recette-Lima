import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../controllers/recipe_controller.dart'; 

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- LOGIQUE DU PLANNING ---
  void _initOrGetPlan() {
    // Si le plan n'existe pas ou qu'il date de plus de 7 jours, on le (re)génère
    if (_weeklyPlan == null || _planDate == null || DateTime.now().difference(_planDate!).inDays >= 7) {
      _weeklyPlan = _generatePlan();
      _planDate = DateTime.now();
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 850 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));

        final filteredList = _filterCategory == 'Tous' 
            ? _controller.all 
            : _controller.all.where((r) => r.category == _filterCategory).toList();

        return Scaffold(
          drawer: isMobile ? Drawer(child: _buildSidebar(isMobile: true)) : null,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text("MES RECETTES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                SizedBox(width: 8),
              ],
            ),
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () => _showFormDialog(), 
                icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 28),
                tooltip: "Ajouter une recette",
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(isMobile: false),
              Expanded(
                child: Stack(
                  children: [
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                      : GridView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: isMobile ? 1.0 : 0.8,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) => _recipeCard(filteredList[index]),
                        ),
                    
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 5,
                          ),
                          onPressed: () => _showPlanner(),
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

  Widget _buildSidebar({required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 240,
      decoration: BoxDecoration(
        color: Colors.black,
        border: isMobile ? null : const Border(right: BorderSide(color: Color(0xFF222222))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("NAVIGATION", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            Expanded(
              child: ListView(
                children: categories.map((cat) => ListTile(
                  title: Text(cat, style: TextStyle(fontSize: 14, color: _filterCategory == cat ? Colors.tealAccent : Colors.white60)),
                  leading: Icon(Icons.folder_open, size: 18, color: _filterCategory == cat ? Colors.tealAccent : Colors.grey[700]),
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

  Widget _recipeCard(Recipe recipe) {
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe, controller: _controller)));
        setState(() {}); 
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
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
                        color: Colors.grey[800], 
                        child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 40)
                      ),
                    ),
            )),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(recipe.part.label, style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormDialog() {
    final titleController = TextEditingController();
    final imageController = TextEditingController(text: 'assets/pictures/pancake.png'); 
    
    MealPart selectedPart = MealPart.plat;
    String selectedCat = categories[1];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text("Nouvelle Recette"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Titre", border: UnderlineInputBorder())),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  items: categories.where((c) => c != 'Tous').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCat = v!),
                  decoration: const InputDecoration(labelText: "Catégorie"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<MealPart>(
                  value: selectedPart,
                  items: MealPart.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPart = v!),
                  decoration: const InputDecoration(labelText: "Partie du repas"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: imageController, 
                  decoration: const InputDecoration(
                    labelText: "Chemin de l'image", 
                    hintText: "ex: assets/pictures/pancake.png",
                    border: UnderlineInputBorder()
                  )
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
              onPressed: () async {
                if(titleController.text.isNotEmpty) {
                  await _controller.store(Recipe(
                    id: DateTime.now().toString(),
                    title: titleController.text,
                    category: selectedCat,
                    label: 'Nouveau',
                    part: selectedPart,
                    imageUrl: imageController.text.isNotEmpty ? imageController.text : 'assets/pictures/pancake.png', 
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

  void _showPlanner() { 
    _initOrGetPlan(); 

    showModalBottomSheet( 
      context: context, 
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 248, 246, 246),
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
                      const Text("PLANNING HEBDOMADAIRE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.teal),
                        tooltip: "Générer une nouvelle semaine",
                        onPressed: () {
                          setState(() {
                            _weeklyPlan = _generatePlan();
                            _planDate = DateTime.now();
                          });
                          setSheetState(() {});
                        },
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: _weeklyPlan!.keys.map((day) => _buildDayPlan(day, _weeklyPlan![day]!, setSheetState)).toList(),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildDayPlan(String day, Map<String, List<Recipe>> meals, StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(day, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)), 
        const Divider(color: Colors.black12),
        _buildMealSection(day, "Midi", meals["Midi"]!, setSheetState),
        _buildMealSection(day, "Soir", meals["Soir"]!, setSheetState),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMealSection(String day, String mealTime, List<Recipe> recipes, StateSetter setSheetState) {
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
                  setSheetState(() {}); 
                },
                child: const Icon(Icons.autorenew, size: 16, color: Colors.teal),
              )
            ],
          ),
          const SizedBox(height: 5), 
          _buildDishRow(day, mealTime, 0, "🥗", recipes[0], setSheetState),
          _buildDishRow(day, mealTime, 1, "🍖", recipes[1], setSheetState),
          _buildDishRow(day, mealTime, 2, "🍰", recipes[2], setSheetState),
        ], 
      ),
    );
  }

  Widget _buildDishRow(String day, String mealTime, int dishIndex, String emoji, Recipe recipe, StateSetter setSheetState) {
    return Row(
      children: [
        Expanded(
          child: Text("$emoji ${recipe.title}", style: const TextStyle(fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
        ),
        IconButton(
          icon: const Icon(Icons.sync, size: 18, color: Colors.black45),
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
              setSheetState(() {});
            }
          },
        ),
      ],
    );
  }
}

// =============================================================================
// VUE DÉTAIL : ÉDITEUR DIRECT STYLE NOTION
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
  
  // Liste des catégories pour l'édition (sans 'Tous')
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

  // Boîte de dialogue pour modifier l'image
  void _showEditImageDialog() {
    final TextEditingController imgController = TextEditingController(text: widget.recipe.imageUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text("Modifier l'image"),
        content: TextField(
          controller: imgController,
          decoration: const InputDecoration(
            labelText: "Chemin ou URL de l'image",
            hintText: "ex: assets/pictures/pancake.png",
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
            onPressed: () {
              setState(() {
                widget.recipe.imageUrl = imgController.text;
              });
              _syncData(); // Déclenche la sauvegarde
              Navigator.pop(context);
            },
            child: const Text("VALIDER"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isMobile ? 250 : 500, 
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            elevation: 0,
            // Les actions (ancienne corbeille) ont été supprimées d'ici
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
                              color: const Color.fromARGB(255, 230, 8, 8), 
                              child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white54, size: 60))
                            ),
                          ),
                  ),
                  // Conteneur en bas à droite pour les boutons d'édition et suppression
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
                            onPressed: _showEditImageDialog,
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
                    style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.bold, letterSpacing: -1),
                    maxLines: null,
                    onChanged: (val) => _syncData(),
                    decoration: const InputDecoration(hintText: "Titre de la recette", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24)),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _editableMealPartProperty(),
                  
                  // Nouveau sélecteur de catégorie ajouté ici
                  _editableCategoryProperty(),
                  
                  _notionProperty(Icons.calendar_today_outlined, "Créé le", "${widget.recipe.createdAt.day}/${widget.recipe.createdAt.month}/${widget.recipe.createdAt.year}"),
                  
                  const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider(color: Color(0xFF2A2A2A))),
                  
                  TextField(
                    controller: _descController,
                    maxLines: null,
                    onChanged: (val) => _syncData(),
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: "Commencez à écrire votre recette ici...", hintStyle: TextStyle(color: Colors.white24)),
                  ),
                  
                  const SizedBox(height: 40),
                  const Text("Ingrédients", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
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
                          if (!isMobile) const Icon(Icons.drag_indicator, size: 16, color: Colors.white24),
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
                              style: const TextStyle(fontSize: 15, color: Colors.tealAccent, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(hintText: "Qté", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24)),
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
                              style: const TextStyle(fontSize: 15, color: Colors.white70),
                              decoration: const InputDecoration(hintText: "Unité", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24)),
                            ),
                          ),
                          
                          Expanded(
                            child: TextField(
                              controller: controllers.name,
                              onChanged: (val) {
                                ing.name = val;
                                widget.controller.update(widget.recipe.id);
                              },
                              style: const TextStyle(fontSize: 15, color: Colors.white),
                              decoration: const InputDecoration(hintText: "Nom de l'ingrédient", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24)),
                            ),
                          ),
                          
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.white24),
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.tealAccent, size: 20),
                          SizedBox(width: 8),
                          Text("Ajouter un ingrédient", style: TextStyle(color: Colors.tealAccent, fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _notionProperty(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _editableMealPartProperty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 16, color: Colors.grey[600]), 
          const SizedBox(width: 12), 
          SizedBox(width: 100, child: Text("Partie", style: TextStyle(color: Colors.grey[600], fontSize: 14))), 
          Expanded( 
            child: DropdownButtonHideUnderline( 
              child: DropdownButton<MealPart>(
                value: widget.recipe.part,
                isDense: true,
                iconSize: 20,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                dropdownColor: const Color(0xFF1A1A1A),
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

  // --- NOUVEAU SÉLECTEUR DE CATÉGORIE ---
  Widget _editableCategoryProperty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.folder_open_outlined, size: 16, color: Colors.grey[600]), 
          const SizedBox(width: 12), 
          SizedBox(width: 100, child: Text("Catégorie", style: TextStyle(color: Colors.grey[600], fontSize: 14))), 
          Expanded( 
            child: DropdownButtonHideUnderline( 
              child: DropdownButton<String>(
                value: editCategories.contains(widget.recipe.category) ? widget.recipe.category : editCategories.first,
                isDense: true,
                iconSize: 20,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                dropdownColor: const Color(0xFF1A1A1A),
                items: editCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (newCat) {
                  if (newCat != null) {
                    setState(() {
                      widget.recipe.category = newCat;
                    });
                    _syncData(); // Sauvegarde automatiquement la catégorie modifiée
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