import 'package:flutter/foundation.dart';

import '../curriculum/curriculum.dart';

enum ReviewRating { morePractice, feltEasy }

class ReviewProgress {
  const ReviewProgress({
    required this.attempts,
    required this.easeStage,
    required this.lastReviewedAt,
    required this.nextReviewAt,
  });
  final int attempts;
  final int easeStage;
  final DateTime lastReviewedAt;
  final DateTime nextReviewAt;

  bool dueAt(DateTime time) => !nextReviewAt.isAfter(time);
}

ReviewProgress scheduleReview(
  ReviewProgress? previous,
  ReviewRating rating,
  DateTime time,
) {
  final now = time.toUtc();
  final stage = rating == ReviewRating.morePractice
      ? 0
      : ((previous?.easeStage ?? 0) + 1).clamp(1, 3);
  final delay = rating == ReviewRating.morePractice
      ? const Duration(hours: 4)
      : Duration(
          days: switch (stage) {
            1 => 1,
            2 => 3,
            _ => 7,
          },
        );
  return ReviewProgress(
    attempts: (previous?.attempts ?? 0) + 1,
    easeStage: stage,
    lastReviewedAt: now,
    nextReviewAt: now.add(delay),
  );
}

abstract interface class ReviewStore {
  Future<Map<String, ReviewProgress>> loadReview();
  Future<void> saveReview(String itemId, ReviewProgress progress);
}

/// Local self-rated practice; never a measured speech score.
class ReviewController extends ChangeNotifier {
  ReviewController(this.store, this.items, this.now);
  final ReviewStore store;
  final List<ReviewItem> items;
  final DateTime Function() now;
  Map<String, ReviewProgress> progress = const {};
  bool loaded = false;
  bool loading = false;
  bool saving = false;
  String? error;
  bool _disposed = false;
  int _revision = 0;
  Future<void>? _pendingWrite;

  Future<bool> load() async {
    if (loading) return false;
    loading = true;
    final revision = ++_revision;
    _notify();
    try {
      final saved = await store.loadReview();
      if (_disposed || revision != _revision) return false;
      final ids = items.map((item) => item.id).toSet();
      progress = Map.unmodifiable({
        for (final entry in saved.entries)
          if (ids.contains(entry.key)) entry.key: entry.value,
      });
      loaded = true;
      error = null;
      return true;
    } catch (_) {
      if (_disposed || revision != _revision) return false;
      error = "We couldn't open your words. Please try again.";
      return false;
    } finally {
      loading = false;
      _notify();
    }
  }

  List<ReviewItem> dueItems() => [
    for (final item in items)
      if (progress[item.id] == null || progress[item.id]!.dueAt(now())) item,
  ];

  Future<bool> rate(ReviewItem item, ReviewRating rating) async {
    if (!loaded || saving || !items.any((known) => known.id == item.id)) {
      return false;
    }
    saving = true;
    error = null;
    final revision = ++_revision;
    _notify();
    try {
      final next = scheduleReview(progress[item.id], rating, now());
      final write = store.saveReview(item.id, next);
      _pendingWrite = write;
      await write;
      if (_disposed || revision != _revision) return false;
      progress = Map.unmodifiable({...progress, item.id: next});
      return true;
    } catch (_) {
      if (_disposed || revision != _revision) return false;
      error = "We couldn't save that word. Please try again.";
      return false;
    } finally {
      _pendingWrite = null;
      saving = false;
      _notify();
    }
  }

  /// Wait for an earlier rating before deleting the same SQLite table.
  Future<void> settleWrites() async {
    try {
      await _pendingWrite;
    } catch (_) {
      // A failed rating has no durable effect. Privacy deletion can continue.
    }
  }

  void clearLocal() {
    _revision++;
    progress = const {};
    loaded = true;
    saving = false;
    error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
