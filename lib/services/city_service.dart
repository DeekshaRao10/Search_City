import 'dart:convert';
import 'package:http/http.dart' as http;

class CityService {
  Future<List<String>> searchCities(String query) async {
    final url = Uri.parse(
      'https://api.milescaira.com/account/city-autocomplete/?query=${Uri.encodeComponent(query)}',
    );

    print('Calling API: $url');

    final response = await http.get(url);

    print('Status code: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print('Suggestions: ${data['suggestions']}');

      return List<String>.from(data['suggestions']);
    } else {
      throw Exception(
        'API Error: ${response.statusCode}',
      );
    }
  }
}