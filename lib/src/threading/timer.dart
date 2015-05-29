part of threading;

class _Timer implements Timer {
  final Thread _thread;

  final Timer _timer;

  _Timer(this._thread, this._timer) {
    if (_thread == null) {
      throw new ArgumentError.notNull("_thread");
    }

    if (_timer == null) {
      throw new ArgumentError.notNull("_timer");
    }
  }

  bool get isActive {
    return _timer.isActive;
  }

  void cancel() {
    if (_timer.isActive) {
      _thread._pendingCallbackCount--;
      _thread._timers.remove(this);
    }

    _timer.cancel();
  }
}
