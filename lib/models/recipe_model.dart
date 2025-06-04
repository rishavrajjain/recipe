class EnhancedRecipe {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final int cookTime;
  final bool isFromReel;
  final List<String> steps;

  const EnhancedRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.cookTime,
    this.isFromReel = false,
    this.steps = const [],
  });
}