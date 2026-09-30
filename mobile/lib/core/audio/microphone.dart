abstract interface class Microphone {
  /// A native interruption (including audio route loss) must never leave the UI recording.
  Stream<void> get interruptions;
  Future<bool> requestPermission();
  Future<void> start();
  Future<String> stop();
  Future<void> discard();
  Future<void> dispose();
}
