import 'package:flutter/foundation.dart';

@immutable
class LearnerProgress {
  const LearnerProgress({
    this.onboardingStep = 0,
    this.profession,
    this.supportLanguage,
    this.dayOnePrompt = 0,
  });
  final int onboardingStep;
  final String? profession;
  final String? supportLanguage;
  final int dayOnePrompt;
  bool get onboarded => onboardingStep == 5;

  LearnerProgress copyWith({
    int? onboardingStep,
    String? profession,
    String? supportLanguage,
    int? dayOnePrompt,
  }) => LearnerProgress(
    onboardingStep: onboardingStep ?? this.onboardingStep,
    profession: profession ?? this.profession,
    supportLanguage: supportLanguage ?? this.supportLanguage,
    dayOnePrompt: dayOnePrompt ?? this.dayOnePrompt,
  );
}

abstract interface class ProgressStore {
  Future<LearnerProgress> load();
  Future<void> save(LearnerProgress progress);
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
}
