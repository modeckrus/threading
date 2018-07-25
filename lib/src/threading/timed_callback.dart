part of threading;

class _TimedCallback {
  final DateTime date;

  final ThreadStart function;

  _TimedCallback(this.date, this.function);
}
