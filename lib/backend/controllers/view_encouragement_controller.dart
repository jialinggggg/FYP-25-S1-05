import 'package:flutter/material.dart';
import 'package:nutri_app/backend/entities/user_measurement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_goal.dart';

class ViewEncouragementController extends ChangeNotifier {
  final SupabaseClient supabaseClient;

  ViewEncouragementController({required this.supabaseClient});

  String _mealStreakMessage = '';
  String get mealStreakMessage => _mealStreakMessage;

  Map<String, String> _weightEncouragement = {};
  Map<String, String> get weightEncouragement => _weightEncouragement;

  Future<void> fetchMealLoggingStreak(String uid) async {
    try {
      final response = await supabaseClient
          .from('meal_log')
          .select('created_at')
          .eq('uid', uid)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        _mealStreakMessage = "No meals logged yet. Start logging your meals!";
        notifyListeners();
        return;
      }

      final loggedDates = response.map((item) {
        final createdAt = DateTime.parse(item['created_at']);
        return DateTime(createdAt.year, createdAt.month, createdAt.day);
      }).toSet().toList();

      loggedDates.sort((a, b) => b.compareTo(a));

      DateTime today = DateTime.now();
      int streakCount = 0;
      bool hasLoggedToday = loggedDates.contains(DateTime(today.year, today.month, today.day));

      DateTime currentDate = hasLoggedToday
          ? DateTime(today.year, today.month, today.day)
          : DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));

      while (loggedDates.contains(currentDate)) {
        streakCount++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      if (hasLoggedToday) {
        if (streakCount >= 15) {_mealStreakMessage = "Consistency is your superpower – $streakCount days in!";}
        else if (streakCount >= 10) {_mealStreakMessage = "You're a meal logging champion! $streakCount days in a row!";}
        else if (streakCount >= 7) {_mealStreakMessage = "Incredible! You're on a $streakCount-day streak!";}
        else if (streakCount >= 5) {_mealStreakMessage = "$streakCount days in – you’re showing true commitment!";}
        else if (streakCount >= 3) {_mealStreakMessage = "Keep up the great work! You're on a $streakCount-day streak!";}
        else {_mealStreakMessage = "Nice! $streakCount days logged in a row – keep going!";}
      } else {
        _mealStreakMessage = "You've logged for $streakCount days straight – log today to keep it alive!";
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Error in fetching meal streak: $e');
    }
  }

  Future<void> fetchWeightEncouragement(String uid) async {
    try {
      final goalResponse = await supabaseClient
          .from('user_goals')
          .select()
          .eq('uid', uid)
          .single();

      if (goalResponse.isEmpty) {
        throw Exception('Failed to fetch user goal');
      }

      final UserGoals userGoal = UserGoals.fromMap(goalResponse);
      final double targetWeight = userGoal.targetWeight;
      final String goal = userGoal.goal;

      final response = await supabaseClient
          .from('user_measurements')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: true);

      if (response.length < 2) {
        _weightEncouragement = {
          'message': "Not enough data yet – keep logging your weight!",
          'status': 'neutral',
        };
        notifyListeners();
        return;
      }

      UserMeasurement firstMeasurement = UserMeasurement.fromMap(response.first);
      UserMeasurement latestMeasurement = UserMeasurement.fromMap(response.last);

      final double change = double.parse((latestMeasurement.weight - firstMeasurement.weight).toStringAsFixed(1));

      if (goal == 'Lose Weight') {
        if (change < 0) {
          if (change.abs() >= 1) {
            _weightEncouragement = {
              'message': "Great job! You've lost ${change.abs()} kg!",
              'status': 'success',
            };
          } else {
            _weightEncouragement = {
              'message': "Small progress! You've lost ${change.abs()} kg.",
              'status': 'neutral',
            };
          }
        } else if (change > 0) {
          _weightEncouragement = {
            'message': "You've gained $change kg – let’s refocus.",
            'status': 'warning',
          };
        } else {
          _weightEncouragement = {
            'message': "No change yet – stay consistent!",
            'status': 'neutral',
          };
        }
      } else if (goal == 'Gain Weight') {
        if (change > 0) {
          if (change >= 1) {
            _weightEncouragement = {
              'message': "Great! You've gained $change kg!",
              'status': 'success',
            };
          } else {
            _weightEncouragement = {
              'message': "You're gaining steadily – $change kg up!",
              'status': 'neutral',
            };
          }
        } else if (change < 0) {
          _weightEncouragement = {
            'message': "You've lost ${change.abs()} kg – let’s fuel up!",
            'status': 'warning',
          };
        } else {
          _weightEncouragement = {
            'message': "Weight unchanged – keep pushing.",
            'status': 'neutral',
          };
        }
      } else {
        double diffPercent = ((latestMeasurement.weight - targetWeight).abs() / targetWeight) * 100;
        if (diffPercent <= 3) {
          _weightEncouragement = {
            'message': "You're maintaining well – great job!",
            'status': 'success',
          };
        } else {
          _weightEncouragement = {
            'message': "You're off track – review your habits.",
            'status': 'warning',
          };
        }
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Error in fetching weight encouragement: $e');
    }
  }
}
