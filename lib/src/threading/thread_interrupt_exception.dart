part of threading;

class ThreadInterruptException implements Exception {
  final String message;

  ThreadInterruptException([this.message]);

  String toString() {
    if (message == null) {
      return "$runtimeType";
    }

    return "$runtimeType: $message";
  }
}
