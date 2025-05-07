import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/edit_goals_controller.dart';
import '../../../../backend/controllers/fetch_user_profile_info_controller.dart';
import '../../../../utils/date_picker.dart';
import '../../../../utils/widget_utils.dart';

class EditGoalsScreen extends StatelessWidget {
  final VoidCallback onUpdate;
  const EditGoalsScreen({super.key, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final fetch = context.read<FetchUserProfileInfoController>();
    final profile = fetch.userProfile!;
    return ChangeNotifierProvider<EditGoalsController>(
      create: (_) => EditGoalsController(
        Supabase.instance.client,
        profile.uid,
        profile.gender,
        profile.weight,
        profile.height,
        profile.birthDate,
      ),
      child: _EditGoalsForm(onUpdate: onUpdate),
    );
  }
}

class _EditGoalsForm extends StatefulWidget {
  final VoidCallback onUpdate;
  const _EditGoalsForm({required this.onUpdate});

  @override
  State<_EditGoalsForm> createState() => _EditGoalsFormState();
}

class _EditGoalsFormState extends State<_EditGoalsForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _targetWeightC,
      _dailyCaloriesC,
      _proteinC,
      _carbsC,
      _fatsC;
  DateTime? _pickedDate;
  String? _dateError;

  // cache the controller reference
  late final EditGoalsController _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _targetWeightC = TextEditingController();
    _dailyCaloriesC = TextEditingController();
    _proteinC = TextEditingController();
    _carbsC = TextEditingController();
    _fatsC = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _ctrl = Provider.of<EditGoalsController>(context);
      _ctrl.addListener(_syncFields);
      _syncFields();
      _initialized = true;
    }
  }

  void _syncFields() {
    _targetWeightC.text = _ctrl.targetWeight.toStringAsFixed(1);
    _dailyCaloriesC.text = _ctrl.dailyCalories.toString();
    _proteinC.text = _ctrl.protein.toStringAsFixed(1);
    _carbsC.text = _ctrl.carbs.toStringAsFixed(1);
    _fatsC.text = _ctrl.fats.toStringAsFixed(1);
    setState(() => _pickedDate = _ctrl.targetDate);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_syncFields);
    _targetWeightC.dispose();
    _dailyCaloriesC.dispose();
    _proteinC.dispose();
    _carbsC.dispose();
    _fatsC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await DatePicker.selectDate(context);
    if (date != null) {
      _ctrl.targetDate = date;
      setState(() => _dateError = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    const goalOptions = [
      'Lose Weight',
      'Gain Weight',
      'Maintain Weight',
      'Gain Muscle',
    ];
    const activityOptions = [
      'Sedentary',
      'Lightly Active',
      'Moderately Active',
      'Very Active',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goals', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Goal dropdown
                    DropdownButtonFormField<String>(
                      value:
                          goalOptions.contains(c.goal) ? c.goal : null,
                      decoration: InputDecoration(
                        labelText: 'Goal',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide:
                              const BorderSide(color: Colors.green),
                        ),
                      ),
                      items: goalOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ))
                          .toList(),
                      onChanged: (v) => c.goal = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Activity dropdown
                    DropdownButtonFormField<String>(
                      value: activityOptions.contains(c.activity)
                          ? c.activity
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Activity Level',
                        border: border,
                        focusedBorder: border.copyWith(
                          borderSide:
                              const BorderSide(color: Colors.green),
                        ),
                      ),
                      items: activityOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ))
                          .toList(),
                      onChanged: (v) => c.activity = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    if (c.hasRecalculated)
                      Text(
                        '* Recalculated based on updated weight, height, goal, activity',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Target Weight
                    WidgetUtils.buildEditableRow(
                      label: 'Target Weight (kg)',
                      controller: _targetWeightC,
                      onDecrease: () {
                        final curr =
                            double.tryParse(_targetWeightC.text) ?? 0;
                        if (curr > 0) {
                          c.targetWeight =
                              (curr - 0.5).clamp(0.0, double.infinity);
                        }
                      },
                      onIncrease: () {
                        final curr =
                            double.tryParse(_targetWeightC.text) ?? 0;
                        c.targetWeight = curr + 0.5;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Target Date
                    Text('Target Date',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                              text: _pickedDate == null
                                  ? ''
                                  : '${_pickedDate!.year}-${_pickedDate!.month.toString().padLeft(2, '0')}-${_pickedDate!.day.toString().padLeft(2, '0')}'),
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Pick date',
                            errorText: _dateError,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate)
                    ]),
                    const SizedBox(height: 24),

                    // Nutrition rows
                    WidgetUtils.buildEditableRow(
                      label: 'Daily Calories',
                      controller: _dailyCaloriesC,
                      onDecrease: () {
                        final curr =
                            int.tryParse(_dailyCaloriesC.text) ?? 0;
                        if (curr > 0) c.dailyCalories = curr - 50;
                      },
                      onIncrease: () {
                        final curr =
                            int.tryParse(_dailyCaloriesC.text) ?? 0;
                        c.dailyCalories = curr + 50;
                      },
                    ),
                    const SizedBox(height: 16),

                    WidgetUtils.buildEditableRow(
                      label: 'Protein (g)',
                      controller: _proteinC,
                      onDecrease: () {
                        final curr =
                            double.tryParse(_proteinC.text) ?? 0;
                        if (curr > 0) c.protein = curr - 5;
                      },
                      onIncrease: () {
                        final curr =
                            double.tryParse(_proteinC.text) ?? 0;
                        c.protein = curr + 5;
                      },
                    ),
                    const SizedBox(height: 16),

                    WidgetUtils.buildEditableRow(
                      label: 'Carbs (g)',
                      controller: _carbsC,
                      onDecrease: () {
                        final curr =
                            double.tryParse(_carbsC.text) ?? 0;
                        if (curr > 0) c.carbs = curr - 5;
                      },
                      onIncrease: () {
                        final curr =
                            double.tryParse(_carbsC.text) ?? 0;
                        c.carbs = curr + 5;
                      },
                    ),
                    const SizedBox(height: 16),

                    WidgetUtils.buildEditableRow(
                      label: 'Fats (g)',
                      controller: _fatsC,
                      onDecrease: () {
                        final curr =
                            double.tryParse(_fatsC.text) ?? 0;
                        if (curr > 0) c.fats = curr - 5;
                      },
                      onIncrease: () {
                        final curr =
                            double.tryParse(_fatsC.text) ?? 0;
                        c.fats = curr + 5;
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: c.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                c.updateGoals().then((_) {
                                  widget.onUpdate();
                                  if (context.mounted) Navigator.pop(context);
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: c.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white,strokeWidth: 2,),
                            )
                          : const Text('Save',style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
