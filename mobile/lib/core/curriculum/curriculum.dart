import 'dart:convert';

class LessonPrompt {
  const LessonPrompt({
    required this.id,
    required this.instruction,
    required this.example,
    required this.hint,
  });
  final String id;
  final String instruction;
  final String example;
  final String hint;

  factory LessonPrompt.fromJson(Map<String, dynamic> json) => LessonPrompt(
    id: json['id'] as String,
    instruction: json['instruction'] as String,
    example: json['example'] as String,
    hint: json['hint'] as String,
  );
}

class LessonConversation {
  const LessonConversation({
    required this.opening,
    required this.goal,
    required this.turnLimit,
    required this.successConditions,
  });
  final String opening;
  final String goal;
  final int turnLimit;
  final List<String> successConditions;

  factory LessonConversation.fromJson(Map<String, dynamic> json) =>
      LessonConversation(
        opening: json['opening'] as String,
        goal: json['goal'] as String,
        turnLimit: json['turn_limit'] as int,
        successConditions: List<String>.unmodifiable(
          json['success_conditions'] as List,
        ),
      );
}

class SalonScenario {
  const SalonScenario({
    required this.id,
    required this.scenarioGoal,
    required this.customerGoal,
    required this.customerPersonality,
    required this.difficulty,
    required this.customerOpening,
    required this.learnerObjectives,
    required this.targetLanguage,
    required this.successConditions,
    required this.turnLimit,
  });
  final String id;
  final String scenarioGoal;
  final String customerGoal;
  final String customerPersonality;
  final int difficulty;
  final String customerOpening;
  final List<String> learnerObjectives;
  final List<String> targetLanguage;
  final List<String> successConditions;
  final int turnLimit;

  factory SalonScenario.fromJson(Map<String, dynamic> json) => SalonScenario(
    id: json['id'] as String,
    scenarioGoal: json['scenario_goal'] as String,
    customerGoal: json['customer_goal'] as String,
    customerPersonality: json['customer_personality'] as String,
    difficulty: json['difficulty'] as int,
    customerOpening: json['customer_opening'] as String,
    learnerObjectives: List<String>.unmodifiable(
      json['learner_objectives'] as List,
    ),
    targetLanguage: List<String>.unmodifiable(json['target_language'] as List),
    successConditions: List<String>.unmodifiable(
      json['success_conditions'] as List,
    ),
    turnLimit: json['turn_limit'] as int,
  );
}

class Lesson {
  const Lesson({
    required this.id,
    required this.day,
    required this.title,
    required this.objective,
    required this.estimatedMinutes,
    required this.challenge,
    required this.targetLanguage,
    required this.prompts,
    this.conversation,
  });
  final String id;
  final int day;
  final String title;
  final String objective;
  final int estimatedMinutes;
  final String challenge;
  final List<String> targetLanguage;
  final List<LessonPrompt> prompts;
  final LessonConversation? conversation;

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as String,
    day: json['day'] as int,
    title: json['title'] as String,
    objective: json['objective'] as String,
    estimatedMinutes: json['estimated_minutes'] as int,
    challenge: json['challenge'] as String,
    targetLanguage: List<String>.unmodifiable(json['target_language'] as List),
    prompts: List.unmodifiable(
      (json['prompts'] as List).map(
        (p) => LessonPrompt.fromJson(p as Map<String, dynamic>),
      ),
    ),
    conversation: json['conversation'] == null
        ? null
        : LessonConversation.fromJson(
            json['conversation'] as Map<String, dynamic>,
          ),
  );
}

class Curriculum {
  const Curriculum(this.lessons, this.salonScenarios);
  final List<Lesson> lessons;
  final List<SalonScenario> salonScenarios;
  Lesson get dayOne => lessons.first;
  Lesson? lessonForDay(int day) =>
      day >= 1 && day <= lessons.length ? lessons[day - 1] : null;
  SalonScenario get firstSalonScenario => salonScenarios.first;

  factory Curriculum.parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    if (json['schema_version'] != 1 ||
        json['profession'] != 'beauty-cosmetology') {
      throw const FormatException('Unsupported curriculum');
    }
    final lessons = (json['lessons'] as List)
        .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
        .toList();
    final scenarios = (json['salon_scenarios'] as List)
        .map((s) => SalonScenario.fromJson(s as Map<String, dynamic>))
        .toList();
    if (scenarios.length != 1 ||
        scenarios.first.id != 'friendly-braids-price' ||
        scenarios.first.difficulty != 1 ||
        scenarios.first.turnLimit != 4 ||
        scenarios.first.scenarioGoal.isEmpty ||
        scenarios.first.customerGoal.isEmpty ||
        scenarios.first.customerPersonality.isEmpty ||
        scenarios.first.customerOpening.isEmpty ||
        scenarios.first.learnerObjectives.isEmpty ||
        scenarios.first.targetLanguage.isEmpty ||
        scenarios.first.successConditions.isEmpty) {
      throw const FormatException('Invalid salon scenario');
    }
    final ids = <String>{};
    if (lessons.length != 5) {
      throw const FormatException('Alpha requires five lessons');
    }
    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      if (lesson.day != i + 1 ||
          lesson.id != 'day-${i + 1}' ||
          lesson.title.isEmpty ||
          lesson.objective.isEmpty ||
          lesson.prompts.isEmpty ||
          lesson.prompts.length < ((i == 0 || i == 4) ? 4 : 3) ||
          lesson.targetLanguage.isEmpty ||
          lesson.estimatedMinutes <= 0) {
        throw const FormatException('Invalid lesson');
      }
      if (i == 0 &&
          (lesson.conversation == null ||
              lesson.conversation!.turnLimit != 3 ||
              lesson.conversation!.opening.isEmpty ||
              lesson.conversation!.goal.isEmpty ||
              lesson.conversation!.successConditions.isEmpty)) {
        throw const FormatException('Invalid Day-1 conversation');
      }
      for (final p in lesson.prompts) {
        if (!ids.add(p.id) ||
            p.instruction.isEmpty ||
            p.example.isEmpty ||
            p.hint.isEmpty) {
          throw const FormatException('Invalid prompt');
        }
      }
    }
    return Curriculum(List.unmodifiable(lessons), List.unmodifiable(scenarios));
  }
}
