import 'package:flutter/foundation.dart';

@immutable
class LearnerProgress {
  const LearnerProgress({
    this.onboardingStep = 0,
    this.profession,
    this.supportLanguage,
    this.dayOnePrompt = 0,
    this.otherDayPrompts = const {},
    this.attemptedPromptIds = const {},
    this.salonRehearsalTurns = const {},
    this.salonRecordedSeconds = const {},
  });
  final int onboardingStep;
  final String? profession;
  final String? supportLanguage;
  final int dayOnePrompt;
  final Map<int, int> otherDayPrompts;

  /// Authored prompts with a saved local speaking attempt; never a quality score.
  final Set<String> attemptedPromptIds;

  /// Most learner replies completed in one rehearsal per authored scenario.
  final Map<String, int> salonRehearsalTurns;

  /// Longest total recorded-answer time in a finished rehearsal, per scenario.
  final Map<String, int> salonRecordedSeconds;
  bool get onboarded => onboardingStep == 5;

  int promptForDay(int day) =>
      day == 1 ? dayOnePrompt : (otherDayPrompts[day] ?? 0);

  bool hasAttempted(String promptId) => attemptedPromptIds.contains(promptId);

  int attemptedCount(Iterable<String> promptIds) =>
      promptIds.where(hasAttempted).length;

  bool finishedPractice(Iterable<String> promptIds) {
    final ids = promptIds.toList();
    return ids.isNotEmpty && ids.every(hasAttempted);
  }

  LearnerProgress withAttemptedPrompt(String promptId) {
    if (promptId.isEmpty) throw ArgumentError('Invalid prompt ID');
    return copyWith(attemptedPromptIds: {...attemptedPromptIds, promptId});
  }

  int bestSalonTurns(String scenarioId) => salonRehearsalTurns[scenarioId] ?? 0;

  int longestSalonRecordedSeconds(String scenarioId) =>
      salonRecordedSeconds[scenarioId] ?? 0;

  LearnerProgress withSalonTurns(String scenarioId, int turns) =>
      withSalonRehearsal(scenarioId, turns, 0);

  LearnerProgress withSalonRehearsal(
    String scenarioId,
    int turns,
    int recordedSeconds,
  ) {
    if (scenarioId.isEmpty ||
        turns < 1 ||
        turns > 6 ||
        recordedSeconds < 0 ||
        recordedSeconds > 360) {
      throw ArgumentError('Invalid salon rehearsal');
    }
    final best = bestSalonTurns(scenarioId);
    final longest = longestSalonRecordedSeconds(scenarioId);
    if (turns <= best && recordedSeconds <= longest) return this;
    return copyWith(
      salonRehearsalTurns: {
        ...salonRehearsalTurns,
        scenarioId: turns > best ? turns : best,
      },
      salonRecordedSeconds: {
        ...salonRecordedSeconds,
        scenarioId: recordedSeconds > longest ? recordedSeconds : longest,
      },
    );
  }

  LearnerProgress withPromptForDay(int day, int index) {
    if (day == 1) return copyWith(dayOnePrompt: index);
    if (day < 2 || day > 5 || index < 0) {
      throw ArgumentError('Invalid daily prompt');
    }
    return copyWith(otherDayPrompts: {...otherDayPrompts, day: index});
  }

  LearnerProgress copyWith({
    int? onboardingStep,
    String? profession,
    String? supportLanguage,
    int? dayOnePrompt,
    Map<int, int>? otherDayPrompts,
    Set<String>? attemptedPromptIds,
    Map<String, int>? salonRehearsalTurns,
    Map<String, int>? salonRecordedSeconds,
  }) => LearnerProgress(
    onboardingStep: onboardingStep ?? this.onboardingStep,
    profession: profession ?? this.profession,
    supportLanguage: supportLanguage ?? this.supportLanguage,
    dayOnePrompt: dayOnePrompt ?? this.dayOnePrompt,
    otherDayPrompts: Map.unmodifiable(otherDayPrompts ?? this.otherDayPrompts),
    attemptedPromptIds: Set.unmodifiable(
      attemptedPromptIds ?? this.attemptedPromptIds,
    ),
    salonRehearsalTurns: Map.unmodifiable(
      salonRehearsalTurns ?? this.salonRehearsalTurns,
    ),
    salonRecordedSeconds: Map.unmodifiable(
      salonRecordedSeconds ?? this.salonRecordedSeconds,
    ),
  );
}

abstract interface class ProgressStore {
  Future<LearnerProgress> load();
  Future<void> save(LearnerProgress progress);
  Future<void> clear();
  Future<void> close();
}

/// Confirm changes only after durable local writes; never invent completion.
class SessionController extends ChangeNotifier {
  SessionController(this.store, this.progress);
  final ProgressStore store;
  LearnerProgress progress;
  bool saving = false;
  String? error;

  Future<bool> update(LearnerProgress next) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await store.save(next);
      progress = next;
      return true;
    } catch (_) {
      error = "We couldn't save your place. Please try again.";
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> reset() async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await store.clear();
      progress = const LearnerProgress();
      return true;
    } catch (_) {
      error = "We couldn't clear your phone data. Please try again.";
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
