import 'package:flutter/foundation.dart';

import '../../core/speech/feedback.dart';

enum TeachingFeedbackState {
  idle,
  sending,
  success,
  offline,
  accessDenied,
  unavailable,
  failure,
}

class FeedbackController extends ChangeNotifier {
  FeedbackController(this.provider);
  final SpeakingFeedback provider;
  TeachingFeedbackState state = TeachingFeedbackState.idle;
  TeachingFeedback? result;
  int _revision = 0;
  bool _disposed = false;

  bool get sending => state == TeachingFeedbackState.sending;

  Future<void> evaluate(
    String lessonId,
    String promptId,
    String transcript,
    String? accessToken,
  ) async {
    if (sending) return;
    if (!provider.configured || accessToken == null) {
      _set(TeachingFeedbackState.unavailable);
      return;
    }
    final revision = ++_revision;
    result = null;
    _set(TeachingFeedbackState.sending);
    try {
      final response = await provider.evaluate(
        lessonId,
        promptId,
        transcript,
        accessToken,
      );
      if (revision != _revision || _disposed) return;
      result = response;
      _set(TeachingFeedbackState.success);
    } on FeedbackException catch (error) {
      if (revision != _revision || _disposed) return;
      _set(switch (error.problem) {
        FeedbackProblem.offline => TeachingFeedbackState.offline,
        FeedbackProblem.accessDenied => TeachingFeedbackState.accessDenied,
        FeedbackProblem.unavailable => TeachingFeedbackState.unavailable,
        FeedbackProblem.failure => TeachingFeedbackState.failure,
      });
    } catch (_) {
      if (revision != _revision || _disposed) return;
      _set(TeachingFeedbackState.failure);
    }
  }

  void _set(TeachingFeedbackState next) {
    if (_disposed) return;
    state = next;
    notifyListeners();
  }

  void clear() {
    _revision++;
    result = null;
    _set(TeachingFeedbackState.idle);
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
