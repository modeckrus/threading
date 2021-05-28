part of threading;

/**
 * The [ThreadStateError] is thrown when a [Thread] is in an invalid
 * [ThreadState] for the method call.
 */
class ThreadStateError extends Error {
  final String? message;

  ThreadStateError([this.message]);

  String toString() {
    if (message == null) {
      return "$runtimeType";
    } else {
      return "$runtimeType: $message";
    }
  }
}
