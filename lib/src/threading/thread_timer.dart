part of threading;

/**
 * The [ThreadTimer] is a timer that executed in a diffirent [Thread].
 */
class ThreadTimer implements Timer {
  late Timer _timer;

  ThreadTimer(Duration duration, void callback()) {
    _timer = Zone.root.createTimer(duration, () {
      var thread = new Thread(callback);
      thread.start();
    });
  }

  ThreadTimer.periodic(Duration period, void callback(ThreadTimer timer)) {
    _timer = Zone.root.createPeriodicTimer(period, (Timer timer) {
      var thread = new Thread(callback);
      thread.start(this);
    });
  }

  bool get isActive {
    return _timer.isActive;
  }

  int get tick {
    return _timer.tick;
  }

  void cancel() {
    _timer.cancel();
  }

  static void run(void callback()) {
    new ThreadTimer(Duration.zero, callback);
  }
}
