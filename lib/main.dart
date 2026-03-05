import 'package:flutter/material.dart';
import 'dart:math';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../controllers/recipe_controller.dart';

void main() => runApp(const CuisineProApp());

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 850 ? 3 : 2);

        final filteredList = _filterCategory == 'Tous' 
            ? _controller.all 
            : _controller.all.where((r) => r.category == _filterCategory).toList();

        return Scaffold(
          appBar: AppBar(
            // Le bouton + est maintenant juste à côté du titre
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("MES RECETTES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showFormDialog(), 
                  icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 28),
                  tooltip: "Ajouter une recette",
                ),
              ],
            ),
            elevation: 0,
            actions: [
              // Le bouton Authentification remplace le + tout à droite
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Ajouter ta logique pour ouvrir la page/fenêtre d'authentification
                    print("Bouton d'authentification cliqué !");
                  },
                  icon: const Icon(Icons.account_circle_outlined, size: 20),
                  label: const Text("Authentification"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    side: const BorderSide(color: Colors.tealAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    GridView.builder( //affiche les recettes sous forme de grille
                      padding: const EdgeInsets.all(20), //espacement autour de la grille
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( // définit la structure de la grille
                        crossAxisCount: crossAxisCount,//nombre de colonnes dans la grille
                        childAspectRatio: 0.8,//ratio largeur/hauteur des éléments de la grille
                        crossAxisSpacing: 10, //espacement horizontal entre les éléments de la grille
                        mainAxisSpacing: 16, //espacement vertical entre les éléments de la grille
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

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(right: BorderSide(color: Color(0xFF222222))),
      ),
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
                title: Text(cat, style: TextStyle(fontSize: 13, color: _filterCategory == cat ? Colors.tealAccent : Colors.white60)),
                leading: Icon(Icons.folder_open, size: 16, color: _filterCategory == cat ? Colors.tealAccent : Colors.grey[700]),
                onTap: () => setState(() => _filterCategory = cat),
              )).toList(),
            ),
          ),
        ],
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
    final urlController = TextEditingController(text: 'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=500');
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
                const SizedBox(height: 15),//size entre titre et categorie
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  items: categories.where((c) => c != 'Tous').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCat = v!),
                  decoration: const InputDecoration(labelText: "Catégorie"),
                ),
                const SizedBox(height: 15), //size entrecategorie et partie du repas
                DropdownButtonFormField<MealPart>(
                  value: selectedPart,
                  items: MealPart.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPart = v!),
                  decoration: const InputDecoration(labelText: "Partie du repas"),
                ),
                const SizedBox(height: 15), //size entre partie du repas et url de l'image
                TextField(controller: urlController, decoration: const InputDecoration(labelText: "URL de l'image", border: UnderlineInputBorder())),//texte pour l'url de l'image
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),//texte du bouton annuler
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),//style du bouton valider
              onPressed: () {
                if(titleController.text.isNotEmpty) {
                  _controller.store(Recipe(
                    id: DateTime.now().toString(),
                    title: titleController.text,//texte pour le titre de la recette
                    category: selectedCat, //catégorie de la recette
                    label: 'Nouveau',//label de la recette
                    part: selectedPart,//partie du repas
                    imageUrl: urlController.text,//url de l'image
                    createdAt: DateTime.now(),//date de création de la recette
                    ingredients: [],//liste d'ingrédients vide pour commencer
                  ));
                  setState(() {}); //rafraîchir la liste des recettes
                  Navigator.pop(context); //  fermer le dialogue après validation
                }
              },
              child: const Text("VALIDER"),//texte du bouton valider
            ),
          ],
        ),//fin du AlertDialog
      ),//fin du dialogue de création de recette
    );//fin du dialogue de création de recette
  }//fin de la fonction de création de recette

  void _showPlanner() { // Affiche le planning hebdomadaire dans un bottom sheet
    final plan = _controller.generateWeeklyPlan();//génère le planning hebdomadaire à partir du controller de recettes
    showModalBottomSheet( // Affiche le planning hebdomadaire dans un bottom sheet
      context: context, //contexte pour afficher le bottom sheet
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 248, 246, 246),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), //style du bottom sheet 
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("PLANNING HEBDOMADAIRE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
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
        Text(day, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
        const Divider(color: Colors.white10),
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
          Text("🥗 ${recipes[0].title}", style: const TextStyle(fontSize: 14)),
          Text("🍖 ${recipes[1].title}", style: const TextStyle(fontSize: 14)),
          Text("🍰 ${recipes[2].title}", style: const TextStyle(fontSize: 14)),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              widget.controller.destroy(widget.recipe.id);
              Navigator.pop(context);
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
            Image.network(widget.recipe.imageUrl, height: 350, width: double.infinity, fit: BoxFit.cover),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1),
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
                          const Icon(Icons.drag_indicator, size: 16, color: Colors.white24),
                          const SizedBox(width: 8),
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
                            width: 60,
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
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}