import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakcraft/core/curriculum/curriculum.dart';
import 'package:speakcraft/core/storage/review_store.dart';

import 'support/fakes.dart';

void main() {
  final item = Curriculum.parse(
    File('assets/curriculum/alpha.json').readAsStringSync(),
  ).reviewItems.first;
  final start = DateTime.utc(2026, 10, 2, 10);

  test('self-rating schedules transparent bounded review intervals', () {
    final first = scheduleReview(null, ReviewRating.feltEasy, start);
    expect(first.attempts, 1);
    expect(first.easeStage, 1);
    expect(first.nextReviewAt, start.add(const Duration(days: 1)));
    expect(first.dueAt(start), isFalse);
    final second = scheduleReview(first, ReviewRating.feltEasy, start);
    expect(second.easeStage, 2);
    expect(second.nextReviewAt, start.add(const Duration(days: 3)));
    final third = scheduleReview(second, ReviewRating.feltEasy, start);
    expect(third.easeStage, 3);
    expect(third.nextReviewAt, start.add(const Duration(days: 7)));
    final again = scheduleReview(third, ReviewRating.morePractice, start);
    expect(again.easeStage, 0);
    expect(again.attempts, 4);
    expect(again.nextReviewAt, start.add(const Duration(hours: 4)));
  });

  test('failed review write keeps the previous visible schedule', () async {
    final store = MemoryProgressStore();
    final controller = ReviewController(store, [item], () => start);
    addTearDown(controller.dispose);
    expect(await controller.load(), isTrue);
    expect(controller.dueItems(), [item]);
    store.failReviewSave = true;
    expect(await controller.rate(item, ReviewRating.feltEasy), isFalse);
    expect(controller.dueItems(), [item]);
    expect(controller.error, contains("couldn't save"));
    store.failReviewSave = false;
    expect(await controller.rate(item, ReviewRating.feltEasy), isTrue);
    expect(controller.dueItems(), isEmpty);
    expect(store.review[item.id]!.attempts, 1);
  });

  test('local erasure can wait for an unfinished review write', () async {
    final store = MemoryProgressStore()..reviewSaveGate = Completer<void>();
    final controller = ReviewController(store, [item], () => start);
    addTearDown(controller.dispose);
    await controller.load();
    final rating = controller.rate(item, ReviewRating.feltEasy);
    var settled = false;
    final wait = controller.settleWrites().then((_) => settled = true);
    await Future<void>.delayed(Duration.zero);
    expect(settled, isFalse);
    store.reviewSaveGate!.complete();
    await wait;
    expect(await rating, isTrue);
    expect(settled, isTrue);
  });
}
