class AnalyzedInstruction {
  final String name;
  final List<InstructionStep> steps;

  AnalyzedInstruction({
    required this.name,
    required this.steps,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'steps': steps.map((step) => step.toMap()).toList(),
    };
  }

  factory AnalyzedInstruction.fromMap(Map<String, dynamic> map) {
    return AnalyzedInstruction(
      name: map['name'] as String,
      steps: (map['steps'] as List).map((i) => InstructionStep.fromMap(i)).toList(),
    );
  }

  AnalyzedInstruction copyWith({
    String? name,
    List<InstructionStep>? steps,
  }) {
    return AnalyzedInstruction(
      name: name ?? this.name,
      steps: steps ?? this.steps,
    );
  }
}

class InstructionStep {
  final int number;
  final String step;

  InstructionStep({
    required this.number,
    required this.step,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'step': step,
    };
  }

  factory InstructionStep.fromMap(Map<String, dynamic> map) {
    return InstructionStep(
      number: map['number'] as int,
      step: map['step'] as String,
    );
  }

  InstructionStep copyWith({
    int? number,
    String? step,
  }) {
    return InstructionStep(
      number: number ?? this.number,
      step: step ?? this.step,
    );
  }
}