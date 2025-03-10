
import '../services/profile_service.dart';

class DataUtils {
  static Future<Map<String, dynamic>> fetchProfileData(String userId) async {
    final profileService = ProfileService();
    return await profileService.fetchProfile(userId);
  }

  static Future<Map<String, dynamic>> fetchGoalsData(String userId) async {
    final profileService = ProfileService();
    return await profileService.fetchGoals(userId);
  }

  static Future<Map<String, dynamic>> fetchMedicalHistoryData(String userId) async {
    final profileService = ProfileService();
    return await profileService.fetchMedicalHistory(userId);
  }

}
