import 'package:flutter/material.dart';
import '../models/recipe_model.dart'; // Ensure this path is correct

class RecipeDetailScreen extends StatelessWidget {
  final EnhancedRecipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (recipe.imageUrl.isNotEmpty)
              Hero(
                tag: 'recipeImage_${recipe.id}',
                child: Image.network(
                  recipe.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder(isFromReel: recipe.isFromReel);
                  },
                ),
              )
            else
              _buildImagePlaceholder(isFromReel: recipe.isFromReel),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecipeMetaInfo(context),
                  const SizedBox(height: 20),
                  if (recipe.description.isNotEmpty)
                    Text(
                      recipe.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[850],
                            height: 1.6,
                            fontSize: 16,
                          ),
                    ),
                  _buildSectionTitle(context, 'Ingredients'),
                  _buildIngredientsList(context),
                  _buildSectionTitle(context, 'Instructions'),
                  _buildStepsList(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({required bool isFromReel}) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey[200],
      child: Icon(
        isFromReel
            ? Icons.ondemand_video_rounded
            : Icons.restaurant_menu_rounded,
        size: 80,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildRecipeMetaInfo(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, color: Colors.orange[700], size: 22),
        const SizedBox(width: 8),
        Text(
          '${recipe.cookTime} minutes',
          style: TextStyle(
              fontSize: 17,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        if (recipe.isFromReel)
          Chip(
            avatar: Icon(Icons.smart_display_rounded,
                color: Colors.pink[700], size: 20),
            label: Text('Reel Import',
                style: TextStyle(
                    color: Colors.pink[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            backgroundColor: Colors.pink[50],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          )
      ],
    );
  }

  Widget _buildIngredientsList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      child: recipe.ingredients.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("No ingredients listed.",
                  style: TextStyle(
                      color: Colors.grey[600], fontStyle: FontStyle.italic)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recipe.ingredients
                  .map((ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Icon(Icons.fiber_manual_record,
                                  color: Colors.orange[600], size: 10),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ingredient,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontSize: 15.5,
                                        color: Colors.grey[850],
                                        height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildStepsList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      child: recipe.steps.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No steps provided for this recipe.',
                style: TextStyle(
                    fontSize: 15.5,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipe.steps.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        radius: 16,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          recipe.steps[index],
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontSize: 15.5,
                                  color: Colors.grey[850],
                                  height: 1.55),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}