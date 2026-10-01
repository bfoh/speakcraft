import 'package:flutter/foundation.dart';

import '../../core/speech/expression.dart';

enum ExpressionStage { intention, repeat, rolePlay, done }

enum ExpressionState {
  idle,
  sending,
  offline,
  accessDenied,
  unavailable,
  invalid,
  failure,
}

class ExpressionController extends ChangeNotifier {
  ExpressionController(this.provider);

  final ExpressionGenerator provider;
  ExpressionStage stage = ExpressionStage.intention;
  ExpressionState state = ExpressionState.idle;
  UsefulExpression? result;
  String? intention;
  String? repetition;
  String? rolePlayReply;
  int _revision = 0;
  bool _disposed = false;

  bool get sending => state == ExpressionState.sending;

  Future<void> generate(String transcript, String? token) async {
    if (sending || stage != ExpressionStage.intention) return;
    if (!provider.configured || token == null) {
      _set(ExpressionState.unavailable);
      return;
    }
    final revision = ++_revision;
    _set(ExpressionState.sending);
    try {
      final generated = await provider.generate(transcript, token);
      if (revision != _revision || _disposed) return;
      intention = transcript;
      result = generated;
      stage = ExpressionStage.repeat;
      _set(ExpressionState.idle);
    } on ExpressionException catch (error) {
      if (revision != _revision || _disposed) return;
      _set(switch (error.problem) {
        ExpressionProblem.offline => ExpressionState.offline,
        ExpressionProblem.accessDenied => ExpressionState.accessDenied,
        ExpressionProblem.unavailable => ExpressionState.unavailable,
        ExpressionProblem.invalid => ExpressionState.invalid,
        ExpressionProblem.failure => ExpressionState.failure,
      });
    } catch (_) {
      if (revision != _revision || _disposed) return;
      _set(ExpressionState.failure);
    }
  }

  void acceptTranscript(String transcript) {
    if (transcript.trim().isEmpty || sending) return;
    if (stage == ExpressionStage.repeat) {
      repetition = transcript;
      stage = ExpressionStage.rolePlay;
    } else if (stage == ExpressionStage.rolePlay) {
      rolePlayReply = transcript;
      stage = ExpressionStage.done;
    }
    _set(ExpressionState.idle);
  }

  void reset() {
    _revision++;
    stage = ExpressionStage.intention;
    result = null;
    intention = null;
    repetition = null;
    rolePlayReply = null;
    _set(ExpressionState.idle);
  }

  void _set(ExpressionState value) {
    if (_disposed) return;
    state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
