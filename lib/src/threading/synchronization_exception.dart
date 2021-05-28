part of threading;

/**
 * The [SynchronizationException] is thrown if the current thread is not the
 * owner of the monitor.
 */
class SynchronizationException implements Exception {
  final String? message;

  SynchronizationException([this.message]);

  String toString() {
    if (message == null) {
      return "$runtimeType";
    }

    return "$runtimeType: $message";
  }
}
