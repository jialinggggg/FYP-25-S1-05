import 'dart:convert';
import 'package:http/http.dart' as http;

class NutridigmService {

  Future<List<Map<String, dynamic>>> fetchTopDoDonts(int conditionId) async {
    final uri = Uri.parse(
      'https://5jocnrfkfb.execute-api.us-east-1.amazonaws.com/PersonalRemedies/nutridigm/api/v2/topdoordonts?subscriptionID=lP8gtN8qaUDouRgqeIob_&healthConditionID=$conditionId',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Unexpected response format from Nutridigm.");
      }
    } else {
      throw Exception('Failed to fetch Nutridigm data for condition ID $conditionId');
    }
  }
}
