import 'package:flutter/foundation.dart';

import '../../core/audio/assessment_capture_store.dart';
import '../../core/curriculum/curriculum.dart';

class AssessmentController extends ChangeNotifier {
  AssessmentController(this.store, this.items, {this.label = 'starting'});
  final AssessmentCaptureStore store;
  final List<CaptureItem> items;
  final String label;
  final Map<String, String> _captures = {};
  int index = 0;
  bool saving = false;
  String? error;
  Future<void>? _pending;

  CaptureItem? get current => index < items.length ? items[index] : null;
  bool get complete => index == items.length;
  int get capturedCount => _captures.length;
  String? pathFor(String itemId) => _captures[itemId];

  Future<bool> saveCurrent(String recordingPath) async {
    if (saving || complete) return false;
    saving = true;
    error = null;
    notifyListeners();
    var saved = false;
    final operation = () async {
      try {
        final item = current!;
        final savedPath = await store.save(item.id, recordingPath);
        _captures[item.id] = savedPath;
        index++;
        saved = true;
      } catch (_) {
        error = "We couldn't save that answer. Your recording is still here. Try again.";
      } finally {
        saving = false;
        notifyListeners();
      }
    }();
    _pending = operation;
    await operation;
    if (identical(_pending, operation)) _pending = null;
    return saved;
  }

  Future<void> settleWrites() async => await _pending;

  Future<bool> clear() async {
    await settleWrites();
    try {
      await store.clear();
      _captures.clear();
      index = 0;
      error = null;
      notifyListeners();
      return true;
    } catch (_) {
      error = "We couldn't clear the $label recordings. Please try again.";
      notifyListeners();
      return false;
    }
  }
}
