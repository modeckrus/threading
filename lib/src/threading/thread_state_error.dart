part of threading;

class ThreadStateError extends Error {
  final String message;

  ThreadStateError([this.message]);

  String toString() {
    if (message == null) {
      return "$runtimeType";
    } else {
      return "$runtimeType: $message";
    }
  }
}
