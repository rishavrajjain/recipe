// lib/services/recipe_api_service.dart
//
// Uses http ^1.2.0 (Dart 3)

import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeApiService {
  /// change to LAN IP if you run the server on another machine
  static const _baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> importRecipeFromReel(
    String reelUrl,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/import-recipe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'link': reelUrl}),
          )
          .timeout(const Duration(seconds: 90));

      final body = jsonDecode(res.body);

      // ----- success -----
      if (res.statusCode == 200 &&
          body is Map<String, dynamic> &&
          body.containsKey('recipe')) {
        return {'success': true, 'recipe': body['recipe']};
      }

      // ----- handled error from FastAPI -----
      if (body is Map && body.containsKey('detail')) {
        return {'success': false, 'error': body['detail']};
      }

      // ----- unexpected -----
      return {
        'success': false,
        'error':
            'Unexpected response (${res.statusCode}): ${res.reasonPhrase ?? ''}'
      };
    } catch (e) {
      return {
        'success': false,
        'error':
            'Network or parsing error. Make sure the backend at $_baseUrl is reachable.\n$e'
      };
    }
  }
}