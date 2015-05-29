part of threading;

class ThreadAbortException implements Exception {
  final String message;

  ThreadAbortException([this.message]);

  String toString() {
    if (message == null) {
      return "$runtimeType";
    }

    return "$runtimeType: $message";
  }
}
