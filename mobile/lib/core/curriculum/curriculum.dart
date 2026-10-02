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

class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.day,
    required this.text,
    required this.cue,
  });
  final String id;
  final int day;
  final String text;
  final String cue;

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
    id: json['id'] as String,
    day: json['day'] as int,
    text: json['text'] as String,
    cue: json['cue'] as String,
  );
}

class BaselineItem {
  const BaselineItem({
    required this.id,
    required this.part,
    required this.title,
    required this.instruction,
    required this.spokenPrompt,
  });
  final String id;
  final int part;
  final String title;
  final String instruction;
  final String spokenPrompt;

  factory BaselineItem.fromJson(Map<String, dynamic> json) => BaselineItem(
    id: json['id'] as String,
    part: json['part'] as int,
    title: json['title'] as String,
    instruction: json['instruction'] as String,
    spokenPrompt: json['spoken_prompt'] as String,
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
  const Curriculum(
    this.lessons,
    this.salonScenarios,
    this.reviewItems,
    this.baselineItems,
  );
  final List<Lesson> lessons;
  final List<SalonScenario> salonScenarios;
  final List<ReviewItem> reviewItems;
  final List<BaselineItem> baselineItems;
  Lesson get dayOne => lessons.first;
  Lesson? lessonForDay(int day) =>
      day >= 1 && day <= lessons.length ? lessons[day - 1] : null;
  SalonScenario get firstSalonScenario => salonScenarios.first;
  SalonScenario? scenarioForId(String id) {
    for (final scenario in salonScenarios) {
      if (scenario.id == id) return scenario;
    }
    return null;
  }

  SalonScenario? scenarioForDay(int day) => switch (day) {
    3 => scenarioForId('welcome-needs-consultation'),
    5 => scenarioForId('complete-salon-conversation'),
    _ => null,
  };

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
    final reviewItems = (json['review_items'] as List)
        .map((item) => ReviewItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final baselineItems = (json['baseline_items'] as List)
        .map((item) => BaselineItem.fromJson(item as Map<String, dynamic>))
        .toList();
    const expectedBaseline = [
      ('baseline-introduction', 1),
      ('baseline-picture', 2),
      ('baseline-procedure', 3),
      ('baseline-listening', 4),
      ('baseline-customer-1', 5),
      ('baseline-customer-2', 5),
      ('baseline-customer-3', 5),
    ];
    if (baselineItems.length != expectedBaseline.length ||
        List.generate(baselineItems.length, (index) => index).any((index) {
          final item = baselineItems[index];
          final (id, part) = expectedBaseline[index];
          return item.id != id ||
              item.part != part ||
              item.title.trim().isEmpty ||
              item.title.length > 80 ||
              item.instruction.trim().isEmpty ||
              item.instruction.length > 240 ||
              item.spokenPrompt.trim().isEmpty ||
              item.spokenPrompt.length > 240;
        })) {
      throw const FormatException('Invalid baseline capture items');
    }
    final reviewIds = <String>{};
    if (reviewItems.length != 10 ||
        reviewItems.any(
          (item) =>
              item.day < 1 ||
              item.day > 5 ||
              item.id.isEmpty ||
              item.id.length > 48 ||
              !reviewIds.add(item.id) ||
              item.text.trim().isEmpty ||
              item.text.length > 160 ||
              item.cue.trim().isEmpty ||
              item.cue.length > 120,
        )) {
      throw const FormatException('Invalid review deck');
    }
    const expected = [
      ('friendly-braids-price', 1, 4),
      ('welcome-needs-consultation', 2, 4),
      ('complete-salon-conversation', 3, 6),
    ];
    if (scenarios.length != expected.length ||
        List.generate(scenarios.length, (index) => index).any((index) {
          final scenario = scenarios[index];
          final (id, difficulty, turnLimit) = expected[index];
          return scenario.id != id ||
              scenario.difficulty != difficulty ||
              scenario.turnLimit != turnLimit ||
              scenario.scenarioGoal.isEmpty ||
              scenario.customerGoal.isEmpty ||
              scenario.customerPersonality.isEmpty ||
              scenario.customerOpening.isEmpty ||
              scenario.learnerObjectives.isEmpty ||
              scenario.targetLanguage.isEmpty ||
              scenario.successConditions.isEmpty;
        })) {
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
    return Curriculum(
      List.unmodifiable(lessons),
      List.unmodifiable(scenarios),
      List.unmodifiable(reviewItems),
      List.unmodifiable(baselineItems),
    );
  }
}
