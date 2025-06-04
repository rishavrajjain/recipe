import 'package:flutter/material.dart';
import '../models/recipe_model.dart'; // Ensure this path is correct

class RecipeCard extends StatelessWidget {
  final EnhancedRecipe recipe;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Hero(
                tag: 'recipeImage_${recipe.id}',
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: recipe.isFromReel
                        ? Colors.pink[50]
                        : Colors.orange[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16.0)),
                    child: recipe.imageUrl.isNotEmpty
                        ? Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  recipe.isFromReel
                                      ? Icons.movie_creation_outlined
                                      : Icons.restaurant_menu,
                                  size: 40,
                                  color: recipe.isFromReel
                                      ? Colors.pink[300]
                                      : Colors.orange[300],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              recipe.isFromReel
                                  ? Icons.movie_creation_outlined
                                  : Icons.restaurant_menu,
                              size: 40,
                              color: recipe.isFromReel
                                  ? Colors.pink[300]
                                  : Colors.orange[300],
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe.description.isNotEmpty)
                      Text(
                        recipe.description,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: recipe.isFromReel
                              ? Colors.pink[400]
                              : Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookTime} min',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}