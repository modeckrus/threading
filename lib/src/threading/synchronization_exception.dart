part of threading;

class SynchronizationException implements Exception {
  final String message;

  SynchronizationException([this.message]);

  String toString() {
    if (message == null) {
      return "$runtimeType";
    }

    return "$runtimeType: $message";
  }
}
