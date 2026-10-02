import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakcraft/core/curriculum/curriculum.dart';

void main() {
  final source = File('assets/curriculum/alpha.json').readAsStringSync();
  test('loads five blueprint days and authored prompts', () {
    final curriculum = Curriculum.parse(source);
    expect(curriculum.lessons.map((l) => l.title), [
      'This Is Me',
      'My Salon',
      'Welcome a Customer',
      'Recommend',
      'Salon Challenge',
    ]);
    expect(curriculum.dayOne.prompts.length, 4);
    expect(curriculum.lessons.map((lesson) => lesson.prompts.length), [
      4,
      3,
      3,
      3,
      4,
    ]);
    expect(curriculum.lessonForDay(5)!.challenge, contains('Greet a customer'));
    expect(curriculum.lessonForDay(6), isNull);
    expect(curriculum.dayOne.challenge, contains('30–60'));
    expect(curriculum.dayOne.conversation!.turnLimit, 3);
    expect(curriculum.dayOne.conversation!.opening, contains('Kora'));
    expect(curriculum.firstSalonScenario.id, 'friendly-braids-price');
    expect(curriculum.firstSalonScenario.difficulty, 1);
    expect(curriculum.firstSalonScenario.successConditions.length, 3);
    expect(curriculum.salonScenarios.length, 3);
    expect(
      curriculum.scenarioForId('welcome-needs-consultation')!.turnLimit,
      4,
    );
    expect(
      curriculum.scenarioForId('complete-salon-conversation')!.turnLimit,
      6,
    );
    expect(curriculum.scenarioForId('unknown'), isNull);
  });
  test('rejects future incompatible versions rather than misreading them', () {
    final data = jsonDecode(source) as Map<String, dynamic>;
    data['schema_version'] = 2;
    expect(() => Curriculum.parse(jsonEncode(data)), throwsFormatException);
  });
  test('rejects duplicate prompt identities', () {
    final data = jsonDecode(source) as Map<String, dynamic>;
    data['lessons'][1]['prompts'][0]['id'] =
        data['lessons'][0]['prompts'][0]['id'];
    expect(() => Curriculum.parse(jsonEncode(data)), throwsFormatException);
  });
  test('rejects an incomplete daily practice sequence', () {
    final data = jsonDecode(source) as Map<String, dynamic>;
    data['lessons'][2]['prompts'].removeLast();
    expect(() => Curriculum.parse(jsonEncode(data)), throwsFormatException);
  });
  test('rejects a missing or unbounded Day-1 conversation', () {
    final data = jsonDecode(source) as Map<String, dynamic>;
    data['lessons'][0]['conversation']['turn_limit'] = 40;
    expect(() => Curriculum.parse(jsonEncode(data)), throwsFormatException);
  });
  test('rejects an unbounded salon scenario', () {
    final data = jsonDecode(source) as Map<String, dynamic>;
    data['salon_scenarios'][0]['turn_limit'] = 40;
    expect(() => Curriculum.parse(jsonEncode(data)), throwsFormatException);
  });
}
