part of threading;

class ThreadTimer implements Timer {
  Timer _timer;

  ThreadTimer(Duration duration, void callback()) {
    _timer = Zone.ROOT.createTimer(duration, () {
      var thread = new Thread(callback);
      thread.start();
    });
  }

  ThreadTimer.periodic(Duration period, void callback(ThreadTimer timer)) {
    _timer = Zone.ROOT.createPeriodicTimer(period, (ThreadTimer timer) {
      var thread = new Thread(callback);
      thread.start(this);
    });
  }

  bool get isActive {
    return _timer.isActive;
  }

  void cancel() {
    _timer.cancel();
  }

  static void run(void callback()) {
    new ThreadTimer(Duration.ZERO, callback);
  }
}
