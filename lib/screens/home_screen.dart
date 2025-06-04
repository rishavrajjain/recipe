// lib/screens/home_screen.dart
//
// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';

import '../models/recipe_model.dart';
import '../services/recipe_api_service.dart';
import '../widgets/processing_indicator.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  final List<EnhancedRecipe> _recipes = [];
  List<EnhancedRecipe> _filteredRecipes = [];

  bool _isProcessingReel = false;

  /// Holds the in-flight import started in the background
  Future<Map<String, dynamic>>? _importFuture;

  // ────────────────────────────────────────────────────────────
  // Lifecycle
  // ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);

    _loadSampleRecipes();
    _filterRecipes('');
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────────────────
  void _onSearchChanged() => _filterRecipes(_searchController.text);

  void _loadSampleRecipes() {
    if (_recipes.isNotEmpty) return; // avoid hot-reload duplicates
    _recipes.addAll(const [
      EnhancedRecipe(
        id: '1',
        name: 'Classic Spaghetti Carbonara',
        description: 'A creamy Italian pasta dish.',
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=400',
        ingredients: [
          '200g Spaghetti',
          '100g Guanciale',
          '2 large Eggs',
          '50g Pecorino Romano',
          'Black Pepper',
        ],
        cookTime: 20,
        steps: [
          'Boil spaghetti.',
          'Cook guanciale.',
          'Mix eggs and cheese.',
          'Combine all ingredients.'
        ],
      ),
      EnhancedRecipe(
        id: '2',
        name: 'Chicken Stir Fry',
        description: 'Quick and healthy chicken stir-fry.',
        imageUrl:
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&q=80&w=400',
        ingredients: [
          '1 lb Chicken Breasts',
          '1 tbsp Soy Sauce',
          'Veggies (Peppers, Carrot, Broccoli)',
          'Garlic, Ginger',
        ],
        cookTime: 25,
        steps: [
          'Marinate chicken.',
          'Stir-fry chicken.',
          'Add veggies.',
          'Add sauce and serve.'
        ],
      ),
      EnhancedRecipe(
        id: '3',
        name: 'Chocolate Chip Cookies',
        description: 'Soft and chewy classic cookies.',
        imageUrl:
            'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?auto=format&fit=crop&q=80&w=400',
        ingredients: [
          '1 cup Butter',
          '¾ cup Sugar',
          '2 Eggs',
          '2¼ cups Flour',
          '2 cups Chocolate Chips',
        ],
        cookTime: 12,
        steps: [
          'Cream butter & sugar.',
          'Add eggs & vanilla.',
          'Combine dry ingredients.',
          'Mix & add chips.',
          'Bake at 375 °F for 9-12 min.',
        ],
      ),
    ]);
  }

  void _filterRecipes(String query) {
    if (!mounted) return;
    setState(() {
      if (query.trim().isEmpty) {
        _filteredRecipes = List.from(_recipes);
      } else {
        final lower = query.toLowerCase();
        _filteredRecipes = _recipes
            .where((r) =>
                r.name.toLowerCase().contains(lower) ||
                r.ingredients.any((i) => i.toLowerCase().contains(lower)))
            .toList();
      }
    });
  }

  void _showSnackBar(String msg,
      {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : (isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline),
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? (isWarning ? Colors.amber[700] : Colors.red[600])
            : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Background import helpers
  // ────────────────────────────────────────────────────────────
  void _startBackgroundImport(String link) {
    if (!mounted) return;
    setState(() => _isProcessingReel = true);

    // kick off without awaiting
    _importFuture = RecipeApiService.importRecipeFromReel(link);
  }

  Future<void> _finalizeImport(String customName) async {
    if (_importFuture == null) {
      _showSnackBar('Import did not start.', isError: true);
      return;
    }

    late Map<String, dynamic> result;
    try {
      result = await _importFuture!;
    } catch (e) {
      setState(() => _isProcessingReel = false);
      _showSnackBar('App error during import. Please try again.',
          isError: true);
      return;
    }

    if (!mounted) return;

    if (result['success'] == true && result['recipe'] != null) {
      final data = Map<String, dynamic>.from(result['recipe']);
      final recipeId = DateTime.now().millisecondsSinceEpoch.toString();
      final recipeName = customName.trim().isNotEmpty
          ? customName.trim()
          : (data['title'] ?? 'Imported Recipe').toString();

      final newRecipe = EnhancedRecipe(
        id: recipeId,
        name: recipeName,
        description: (data['description'] ?? 'Recipe from Reel').toString(),
        imageUrl: (data['image_url'] ?? data['thumbnail_url'] ?? '').toString(),
        ingredients: (data['ingredients'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            ['Ingredients not detected. Add manually.'],
        cookTime: data['cook_time_minutes'] is int
            ? data['cook_time_minutes']
            : (data['total_time_minutes'] is int
                ? data['total_time_minutes']
                : 25),
        steps: (data['steps'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            ['Steps not detected. Add manually.'],
        isFromReel: true,
      );

      setState(() {
        _recipes.insert(0, newRecipe);
        _filterRecipes(_searchController.text);
        _isProcessingReel = false;
      });

      _showSnackBar('Recipe "$recipeName" imported!');
    } else {
      setState(() => _isProcessingReel = false);
      _showSnackBar(result['error']?.toString() ?? 'Failed to extract recipe.',
          isError: true);
    }
  }

  // ────────────────────────────────────────────────────────────
  // Reel import flow
  // ────────────────────────────────────────────────────────────
  void _handleReelLinkSubmission(BuildContext ctx, String link) {
    Navigator.of(ctx).pop();

    if (link.trim().isEmpty) {
      _showSnackBar('Please enter a link.',
          isError: true, isWarning: true);
      return;
    }

    final pattern = RegExp(
        r'^(https?:\/\/)?(www\.)?instagram\.com\/(reel|reels|p)\/[\w-]+\/?');
    if (pattern.hasMatch(link)) {
      _startBackgroundImport(link.trim()); // 1️⃣ kick off

      _showRecipeNameModal();               // 2️⃣ ask for name
    } else {
      _showSnackBar('Enter a valid Instagram Reel link.',
          isError: true, isWarning: true);
    }
  }

  void _showRecipeNameModal() {
    if (!mounted) return;

    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(sheetCtx).canvasColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restaurant_menu_rounded,
                          color: Colors.orange[600], size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name Your Recipe',
                            style: Theme.of(sheetCtx)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a custom name or leave empty for auto-detection',
                            style: Theme.of(sheetCtx)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tip box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          color: Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'We’ll extract the recipe name automatically if you leave this blank.',
                          style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Input
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter custom recipe name (optional)',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.edit_outlined,
                        color: Colors.grey[500], size: 20),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Colors.orange[400]!, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  autofocus: true,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final customName = nameController.text.trim();
                          Navigator.of(sheetCtx).pop();

                          await _finalizeImport(customName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Done',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // UI builders
  // ────────────────────────────────────────────────────────────
  void _openRecipeDetail(EnhancedRecipe recipe) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
    );
  }

  Widget _buildEmptyState() {
    final noRecipesYet = _searchController.text.isEmpty && _recipes.isEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            noRecipesYet
                ? 'No recipes yet.\nTap Import Reel to add one!'
                : 'No recipes found for "${_searchController.text}".',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('My Recipes',
            style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search recipes or ingredients...',
                prefixIcon: Icon(Icons.search, color: Colors.orange),
              ),
            ),
          ),
          if (_isProcessingReel)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ProcessingIndicator(),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _filteredRecipes.isEmpty && !_isProcessingReel
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.only(top: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (_, i) => RecipeCard(
                        recipe: _filteredRecipes[i],
                        onTap: () => _openRecipeDetail(_filteredRecipes[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPasteReelLinkModal,
        backgroundColor: Colors.pink[400],
        elevation: 4,
        icon: const Icon(Icons.movie_creation_outlined, color: Colors.white),
        label: const Text('Import Reel',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Paste-link modal (unchanged)
  // ────────────────────────────────────────────────────────────
  void _showPasteReelLinkModal() {
    if (!mounted) return;

    final linkController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(sheetCtx).canvasColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink[400]!, Colors.purple[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.movie_creation_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Recipe from Reel',
                            style: Theme.of(sheetCtx)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transform Instagram recipes into your collection',
                            style: Theme.of(sheetCtx)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Instruction
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Copy the Instagram Reel link and paste it below',
                          style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      hintText: 'https://www.instagram.com/reel/...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.link_rounded,
                            color: Colors.pink[600], size: 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    autofocus: true,
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleReelLinkSubmission(
                            sheetCtx, linkController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Next',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}