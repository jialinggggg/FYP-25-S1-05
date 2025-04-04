import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_goal.dart';

class UserGoalsRepository {
  final SupabaseClient _supabase;

  UserGoalsRepository(this._supabase);

  Future<void> insertGoals(UserGoals goals) async {
    try {
      await _supabase.from('user_goals').insert(goals.toMap());
    } catch (error) {
      throw Exception('Unable to insert goals: $error');
    }
  }

  Future<UserGoals?> fetchGoals(String uid) async {
    try {
      final response = await _supabase
          .from('user_goals')
          .select()
          .eq('uid', uid)
          .single();
      return UserGoals.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateGoals(UserGoals goals) async {
    try {
      await _supabase.from('user_goals')
          .update(goals.toMap())
          .eq('uid', goals.uid);
    } catch (e) {
      throw Exception('Failed to update goals: $e');
    }
  }

  Future<void> deleteGoals(String uid) async {
    try {
      await _supabase.from('user_goals').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete goals: $e');
    }
  }
}