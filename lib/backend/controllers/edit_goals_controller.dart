import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_goal.dart';
import '../signup/input_validation_service.dart';

class EditGoalsController extends ChangeNotifier {
  final SupabaseClient _supabase;
  final InputValidationService _validationService;
  final String userId;

  EditGoalsController(
    this._supabase,
    this.userId,
    String initialGender,
    double initialWeight,
    double initialHeight,
    DateTime initialBirthDate,
  )   : _validationService = InputValidationService(),
        _gender = initialGender,
        _weight = initialWeight,
        _height = initialHeight,
        _birthDate = initialBirthDate {
    loadGoals();
  }

  // ─ State ─────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;

  String _goal = '';
  String _activity = '';
  double _targetWeight = 0.0;
  DateTime? _targetDate;
  int _dailyCalories = 0;
  double _protein = 0.0;
  double _carbs = 0.0;
  double _fats = 0.0;

  // fixed user‐profile info for recalc
  final String _gender;
  final double _weight;
  final double _height;
  final DateTime _birthDate;

  bool _hasRecalculated = false;

  // ─ Getters ───────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get goal => _goal;
  String get activity => _activity;
  double get targetWeight => _targetWeight;
  DateTime? get targetDate => _targetDate;
  int get dailyCalories => _dailyCalories;
  double get protein => _protein;
  double get carbs => _carbs;
  double get fats => _fats;

  /// true once user has edited goal or activity
  bool get hasRecalculated => _hasRecalculated;

  // ─ Setters ───────────────────────────────────────────────────────────
  set goal(String v) {
    _goal = v;
    _hasRecalculated = true;
    notifyListeners();
    _recalculate();
  }

  set activity(String v) {
    _activity = v;
    _hasRecalculated = true;
    notifyListeners();
    _recalculate();
  }

  // manual setters for editable post‐calc targets
  set targetWeight(double v) {
    _targetWeight = v;
    notifyListeners();
  }

  set targetDate(DateTime? v) {
    _targetDate = v;
    notifyListeners();
  }

  set dailyCalories(int v) {
    _dailyCalories = v;
    notifyListeners();
  }

  set protein(double v) {
    _protein = v;
    notifyListeners();
  }

  set carbs(double v) {
    _carbs = v;
    notifyListeners();
  }

  set fats(double v) {
    _fats = v;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  // ─ Load / Save ────────────────────────────────────────────────────────

  Future<void> loadGoals() async {
    _setLoading(true);
    try {
      final resp = await _supabase
          .from('user_goals')
          .select()
          .eq('uid', userId)
          .single();

      final g = UserGoals.fromMap(resp);

      // seed from DB:
      _goal = g.goal;
      _activity = g.activity;
      _targetWeight = g.targetWeight;
      _targetDate = g.targetDate;
      _dailyCalories = g.dailyCalories;
      _protein = g.protein;
      _carbs = g.carbs;
      _fats = g.fats;
      _hasRecalculated = false;

      _setError(null);
    } catch (e) {
      _setError('Failed to load goals: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateGoals() async {
    _setLoading(true);
    try {
      await _supabase
          .from('user_goals')
          .update({
            'goal': _goal,
            'activity': _activity,
            'target_weight': _targetWeight,
            'target_date': _targetDate?.toIso8601String(),
            'daily_calories': _dailyCalories,
            'protein': _protein,
            'carbs': _carbs,
            'fats': _fats,
          })
          .eq('uid', userId);
      _setError(null);
    } catch (e) {
      _setError('Failed to update goals: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─ Recaclulation ──────────────────────────────────────────────────────

  void _recalculate() {
    if (_goal.isEmpty || _activity.isEmpty) return;

    final results = _validationService.calculateRecommendedGoals(
      gender: _gender,
      weight: _weight,
      height: _height,
      birthDate: _birthDate,
      goal: _goal,
      activity: _activity,
    );

    _targetWeight = results['targetWeight'] as double;
    _targetDate = results['targetDate'] as DateTime;
    _dailyCalories = results['dailyCalories'] as int;
    _protein = results['protein'] as double;
    _carbs = results['carbs'] as double;
    _fats = results['fats'] as double;

    notifyListeners();
  }
}
