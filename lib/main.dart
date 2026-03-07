import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../controllers/recipe_controller.dart'; 

Future<void> main() async {
  // Obligatoire pour initialiser des plugins Flutter (comme Supabase) avant le runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase avec tes identifiants
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
  
  // Variable pour gérer l'affichage du spinner de chargement
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    // On demande au contrôleur de télécharger les recettes depuis Supabase !
    await _controller.fetchRecipes();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Définition des points de rupture responsive
        bool isMobile = constraints.maxWidth < 750;
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 850 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));

        final filteredList = _filterCategory == 'Tous' 
            ? _controller.all 
            : _controller.all.where((r) => r.category == _filterCategory).toList();

        return Scaffold(
          // Ajout du Drawer (menu hamburger) uniquement sur mobile
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
              // Affichage de la sidebar fixe sur ordinateur/tablette
              if (!isMobile) _buildSidebar(isMobile: false),
              Expanded(
                child: Stack(
                  children: [
                    // Affichage conditionnel : Spinner de chargement OU la Grille de recettes
                    _isLoading 
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.tealAccent)
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100), // Espace en bas pour le bouton
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: isMobile ? 1.0 : 0.8, // Ajustement du ratio sur mobile
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
                      Navigator.pop(context); // Fermer le drawer sur mobile après un clic
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
        // On attend (await) que la page de détail se ferme. Si on a supprimé/modifié la recette, on met à jour la grille
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
              child: Image.network(recipe.imageUrl, fit: BoxFit.cover, width: double.infinity),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
              // Ajout de "async" pour pouvoir envoyer la donnée sur Supabase
              onPressed: () async {
                if(titleController.text.isNotEmpty) {
                  // On attend que la BDD crée la recette avec "await"
                  await _controller.store(Recipe(
                    id: DateTime.now().toString(), // Cet ID temporaire sera écrasé par le vrai UUID généré par la base de données
                    title: titleController.text,
                    category: selectedCat,
                    label: 'Nouveau',
                    part: selectedPart,
                    imageUrl: 'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=500', 
                    createdAt: DateTime.now(),
                    ingredients: [],
                  ));
                  // On recharge l'affichage local
                  setState(() {});
                  // Fermeture du modal de création
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
    final plan = _controller.generateWeeklyPlan();
    showModalBottomSheet( 
      context: context, 
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 248, 246, 246),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), 
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("PLANNING HEBDOMADAIRE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)), // teal au lieu de tealAccent car fond blanc
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: plan.keys.map((day) => _buildDayPlan(day, plan[day]!)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPlan(String day, Map<String, List<Recipe>> meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(day, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)), // teal car fond blanc
        const Divider(color: Colors.black12),
        _buildMealSection("MIDI", meals["Midi"]!),
        _buildMealSection("SOIR", meals["Soir"]!),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMealSection(String title, List<Recipe> recipes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5), 
          Text("🥗 ${recipes[0].title}", style: const TextStyle(fontSize: 14, color: Colors.black87)), 
          Text("🍖 ${recipes[1].title}", style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text("🍰 ${recipes[2].title}", style: const TextStyle(fontSize: 14, color: Colors.black87)), 
        ], 
      ),
    );
  }
}

// =============================================================================
// VUE DÉTAIL : ÉDITEUR DIRECT STYLE NOTION (Titre, Desc. ET Ingrédients)
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de l'écran pour le responsive de la page détail
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              // On attend que la suppression s'effectue dans la base
              await widget.controller.destroy(widget.recipe.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(widget.recipe.imageUrl, height: isMobile ? 250 : 350, width: double.infinity, fit: BoxFit.cover),
            
            Padding(
              // Padding ajusté pour mobile et desktop
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 32.0, vertical: isMobile ? 24.0 : 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    // Taille de titre responsive
                    style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.bold, letterSpacing: -1),
                    maxLines: null,
                    onChanged: (val) => _syncData(),
                    decoration: const InputDecoration(hintText: "Titre de la recette", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24)),
                  ),
                  
                  const SizedBox(height: 24),
                  _notionProperty(Icons.person_outline, "Owner", widget.recipe.owner),
                  _notionProperty(Icons.tag_outlined, "Partie", widget.recipe.part.label),
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
                            width: 50, // un peu réduit pour laisser plus de place au nom sur mobile
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
          ],
        ),
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
}