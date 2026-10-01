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
  const Curriculum(this.lessons);
  final List<Lesson> lessons;
  Lesson get dayOne => lessons.first;

  factory Curriculum.parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    if (json['schema_version'] != 1 ||
        json['profession'] != 'beauty-cosmetology') {
      throw const FormatException('Unsupported curriculum');
    }
    final lessons = (json['lessons'] as List)
        .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
        .toList();
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
    return Curriculum(List.unmodifiable(lessons));
  }
}
