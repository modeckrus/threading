part of threading;

class _ThreadCallback {
  final Function function;

  final Thread thread;

  _ThreadCallback(this.thread, this.function);
}
