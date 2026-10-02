import 'package:flutter/foundation.dart';

import '../../core/speech/conversation.dart';

enum ConversationState {
  idle,
  sending,
  success,
  offline,
  accessDenied,
  unavailable,
  invalidAnswer,
  failure,
}

class ConversationController extends ChangeNotifier {
  ConversationController({
    required this.provider,
    required this.lessonId,
    required this.opening,
    required this.turnLimit,
  }) : turns = [ConversationTurn(ConversationSpeaker.kora, opening)];

  final KoraConversation provider;
  final String lessonId;
  final String opening;
  final int turnLimit;
  List<ConversationTurn> turns;
  ConversationState state = ConversationState.idle;
  bool waitingForRecording = false;
  Duration recordedAnswerTime = Duration.zero;
  int _revision = 0;
  bool _disposed = false;

  bool get sending => state == ConversationState.sending;
  int get learnerTurns => (turns.length - 1) ~/ 2;
  bool get complete =>
      learnerTurns >= turnLimit ||
      (learnerTurns > 0 &&
          state == ConversationState.success &&
          !waitingForRecording);

  Future<void> send(
    String transcript,
    String? accessToken, {
    Duration? recordedDuration,
  }) async {
    if (sending || waitingForRecording || complete) return;
    if (!provider.configured || accessToken == null) {
      _set(ConversationState.unavailable);
      return;
    }
    final revision = ++_revision;
    _set(ConversationState.sending);
    try {
      final response = await provider.respond(
        lessonId,
        List.unmodifiable(turns),
        transcript,
        accessToken,
      );
      if (revision != _revision || _disposed) return;
      turns = [
        ...turns,
        ConversationTurn(ConversationSpeaker.learner, transcript),
        ConversationTurn(ConversationSpeaker.kora, response.spokenText),
      ];
      if (recordedDuration != null && recordedDuration > Duration.zero) {
        recordedAnswerTime += recordedDuration;
      }
      waitingForRecording =
          response.nextQuestion != null && learnerTurns < turnLimit;
      _set(ConversationState.success);
    } on ConversationException catch (error) {
      if (revision != _revision || _disposed) return;
      _set(switch (error.problem) {
        ConversationProblem.offline => ConversationState.offline,
        ConversationProblem.accessDenied => ConversationState.accessDenied,
        ConversationProblem.unavailable => ConversationState.unavailable,
        ConversationProblem.invalidAnswer => ConversationState.invalidAnswer,
        ConversationProblem.failure => ConversationState.failure,
      });
    } catch (_) {
      if (revision != _revision || _disposed) return;
      _set(ConversationState.failure);
    }
  }

  void beginNewRecording() {
    if (complete || sending) return;
    waitingForRecording = false;
    _set(ConversationState.idle);
  }

  void reset() {
    _revision++;
    turns = [ConversationTurn(ConversationSpeaker.kora, opening)];
    recordedAnswerTime = Duration.zero;
    waitingForRecording = false;
    _set(ConversationState.idle);
  }

  void _set(ConversationState next) {
    if (_disposed) return;
    state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
