import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../backend/controllers/edit_medical_hist_controller.dart';
import '../../../../backend/controllers/fetch_user_profile_info_controller.dart';
import '../../../../backend/api/spoonacular_service.dart';

class EditMedicalHistScreen extends StatelessWidget {
  final VoidCallback onUpdate;
  const EditMedicalHistScreen({super.key, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<FetchUserProfileInfoController>().userProfile!.uid;
    return ChangeNotifierProvider<EditMedicalHistController>(
      create: (_) => EditMedicalHistController(
        supabaseClient: Supabase.instance.client,
      )..fetchMedicalHistory(uid),
      child: _EditMedicalHistForm(uid: uid, onUpdate: onUpdate),
    );
  }
}

class _EditMedicalHistForm extends StatefulWidget {
  final String uid;
  final VoidCallback onUpdate;
  const _EditMedicalHistForm({required this.uid, required this.onUpdate});

  @override
  __EditMedicalHistFormState createState() => __EditMedicalHistFormState();
}

class __EditMedicalHistFormState extends State<_EditMedicalHistForm> {
  static const _preExistingOptions = [
    'High blood pressure',
    'Type 2 diabetes',
  ];

  late final EditMedicalHistController _ctrl;
  final List<String?> _preSelected = [];
  final List<TextEditingController> _allergyCtrls = [];
  final List<List<Map<String, dynamic>>> _allergySuggestions = [];
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = context.read<EditMedicalHistController>();
    _ctrl.addListener(_syncState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && !_ctrl.isLoading) {
      _syncState();
      _initialized = true;
    }
  }

  void _syncState() {
    _preSelected
      ..clear()
      ..addAll(_ctrl.preExistingConditions);

    // Dispose all allergy controllers before clearing the lists
    for (var c in _allergyCtrls) {
      c.dispose();
    }

    _allergyCtrls.clear();
    _allergySuggestions.clear();

    for (var allergy in _ctrl.allergies) {
      _allergyCtrls.add(TextEditingController(text: allergy));
      _allergySuggestions.add([]);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_syncState);
    for (var c in _allergyCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPreExistingField() => setState(() => _preSelected.add(null));
  void _removePreExistingField(int i) => setState(() => _preSelected.removeAt(i));

  void _addAllergyField() {
    setState(() {
      _allergyCtrls.add(TextEditingController());
      _allergySuggestions.add([]);
    });
  }

  void _removeAllergyField(int i) {
    setState(() {
      _allergyCtrls.removeAt(i).dispose();
      _allergySuggestions.removeAt(i);
    });
  }

  Future<void> _onAllergyChanged(String q, int i) async {
    if (q.isEmpty) {
      setState(() => _allergySuggestions[i] = []);
      return;
    }
    try {
      final res = await SpoonacularService().searchIngredients(query: q);
      setState(() => _allergySuggestions[i] = res);
    } catch (_) {
      setState(() => _allergySuggestions[i] = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medical History', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        elevation: 1,
      ),
      body: c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // — Pre-existing Conditions —
                    Text(
                      'Do you have any pre-existing medical conditions?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'If yes, select medical conditions',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    ..._preSelected.asMap().entries.map((entry) {
                      final i = entry.key;
                      final val = entry.value;
                      final opts = _preExistingOptions
                          .where((o) => o == val || !_preSelected.contains(o))
                          .toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: val,
                                decoration: InputDecoration(
                                  hintText: 'Select condition',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: opts
                                    .map((o) => DropdownMenuItem(
                                          value: o,
                                          child: Text(o),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _preSelected[i] = v),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removePreExistingField(i),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_preExistingOptions
                        .where((opt) => !_preSelected.contains(opt))
                        .isNotEmpty)
                      TextButton(
                        onPressed: _addPreExistingField,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Add Medical Condition',
                                style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // — Allergies —
                    Text(
                      'Do you have any known allergies?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'If yes, add allergies',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    ..._allergyCtrls.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ctrl = entry.value;
                      final sugg = _allergySuggestions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: ctrl,
                                    decoration: InputDecoration(
                                      hintText: 'Enter allergy',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (txt) => _onAllergyChanged(txt, i),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeAllergyField(i),
                                ),
                              ],
                            ),
                            if (sugg.isNotEmpty)
                              Container(
                                constraints: BoxConstraints(maxHeight: 150),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: sugg.length,
                                  itemBuilder: (_, j) {
                                    final item = sugg[j];
                                    return ListTile(
                                      leading: item['image'] != null
                                          ? Image.network(
                                              item['image'],
                                              width: 24,
                                              height: 24,
                                            )
                                          : null,
                                      title: Text(item['name']),
                                      onTap: () {
                                        setState(() {
                                          ctrl.text = item['name'];
                                          _allergySuggestions[i] = [];
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton(
                      onPressed: _addAllergyField,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Add Allergy', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: c.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final pre = _preSelected.whereType<String>().toList();
                                final alls = _allergyCtrls
                                    .map((c) => c.text.trim())
                                    .where((t) => t.isNotEmpty)
                                    .toList();
                                await c.updateMedicalHistory(
                                  widget.uid,
                                  preExisting: pre,
                                  allergiesList: alls,
                                );
                                widget.onUpdate();
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: c.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
