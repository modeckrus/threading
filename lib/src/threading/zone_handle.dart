part of threading;

class _ZoneHandle {
  static final LinkedList<_LinkedListEntry<_TimedCallback>> _timedCallbacks =
      new LinkedList<_LinkedListEntry<_TimedCallback>>();

  static bool _isSystemTimer = false;

  final Thread thread;

  Zone zone;

  _ZoneHandle(this.thread) {
    if (thread == null) {
      throw new ArgumentError.notNull("thread");
    }

    zone = Zone.root.fork(specification: _createSpecification());
  }

  Timer _createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone,
      Duration period, void f(Timer timer)) {
    _log("createPeriodicTimer", f);
    void callback(Timer timer) {
      _log("createPeriodicTimer callback", f);
      var callback = new _ThreadCallback(thread, () => f(timer));
      thread._scheduledCallbackCount++;
      _EventLoop.current._addTimerCallback(callback);
    }

    var timer = parent.createPeriodicTimer(zone, period, callback);
    timer = new _Timer(thread, timer);
    thread._pendingCallbackCount++;
    thread._timers.add(timer);
    return timer;
  }

  ZoneSpecification _createSpecification() {
    return new ZoneSpecification(
        createPeriodicTimer: _createPeriodicTimer,
        createTimer: _createTimer,
        errorCallback: _errorCallback,
        fork: _fork,
        handleUncaughtError: _handleUncaughtError,
        print: _print,
        registerBinaryCallback: _registerBinaryCallback,
        registerCallback: _registerCallback,
        registerUnaryCallback: _registerUnaryCallback,
        run: _run,
        runBinary: _runBinary,
        runUnary: _runUnary,
        scheduleMicrotask: _scheduleMicrotask);
  }

  Timer _createTimer(
      Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f()) {
    _log("createTimer", f);
    var isSystemTimer = _isSystemTimer;
    _isSystemTimer = false;
    Timer timer;
    void callback() {
      _log("createTimer callback", f);
      thread._pendingCallbackCount--;
      thread._scheduledCallbackCount++;
      thread._timers.remove(timer);
      if (isSystemTimer) {
        f();
      } else {
        var callback = new _ThreadCallback(thread, f);
        _EventLoop.current._addTimerCallback(callback);
      }
    }

    timer = parent.createTimer(zone, duration, callback);
    timer = new _Timer(thread, timer);
    thread._pendingCallbackCount++;
    thread._timers.add(timer);
    return timer;
  }

  AsyncError _errorCallback(Zone self, ZoneDelegate parent, Zone zone,
      Object error, StackTrace stackTrace) {
    return parent.errorCallback(zone, error, stackTrace);
  }

  Zone _fork(Zone self, ZoneDelegate parent, Zone zone,
      ZoneSpecification specification, Map zoneValues) {
    return parent.fork(Zone.root, specification, zoneValues);
  }

  dynamic _handleUncaughtError(Zone self, ZoneDelegate parent, Zone zone,
      Object error, StackTrace stackTrace) {
    return thread._handleUncaughtError(
        zone, error, stackTrace, parent.handleUncaughtError);
  }

  void _print(Zone self, ZoneDelegate parent, Zone zone, String line) {
    parent.print(zone, line);
  }

  ZoneBinaryCallback<R, T1, T2> _registerBinaryCallback<R, T1, T2>(
      Zone self, ZoneDelegate parent, Zone zone, R f(T1 arg1, T2 arg2)) {
    _log("registerBinaryCallback", f);
    R callback(T1 arg1, T2 arg2) {
      _log("registerBinaryCallback callback", f);
      Thread previous;
      try {
        previous = thread._enter();
        return f(arg1, arg2);
      } finally {
        thread._leave(previous);
      }
    }

    return parent.registerBinaryCallback(zone, callback);
  }

  ZoneCallback<R> _registerCallback<R>(
      Zone self, ZoneDelegate parent, Zone zone, R f()) {
    _log("registerCallback", f);
    R callback() {
      _log("registerCallback callback", f);
      Thread previous;
      try {
        previous = thread._enter();
        return f();
      } finally {
        thread._leave(previous);
      }
    }

    return parent.registerCallback(zone, callback);
  }

  ZoneUnaryCallback<R, T> _registerUnaryCallback<R, T>(
      Zone self, ZoneDelegate parent, Zone zone, R f(T arg)) {
    _log("registerUnaryCallback", f);
    R callback(T arg) {
      _log("registerUnaryCallback callback", f);
      Thread previous;
      try {
        previous = thread._enter();
        return f(arg);
      } finally {
        thread._leave(previous);
      }
    }

    return parent.registerUnaryCallback(zone, callback);
  }

  R _run<R>(Zone self, ZoneDelegate parent, Zone zone, R f()) {
    return parent.run(zone, f);
  }

  // TODO: remove
  R _runBinary<R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    return parent.runBinary<R, T1, T2>(zone, f, arg1, arg2);
  }

  // TODO: remove
  R _runUnary<R, T>(
      Zone self, ZoneDelegate parent, Zone zone, R f(T arg), T arg) {
    return parent.runUnary<R, T>(zone, f, arg);
  }

  // TODO: remove
  void _scheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()) {
    // TODO: Remove
    _log("scheduleMicrotask", f);
    var isYield = thread._isYield;
    thread._isYield = false;
    void callback() {
      _log("scheduleMicrotask callback", f);
      _processPendingZoneTasks();
      thread._pendingCallbackCount--;
      thread._scheduledCallbackCount++;
      var callback = new _ThreadCallback(thread, f);
      if (isYield) {
        _EventLoop.current._addWakeupCallback(callback);
      } else {
        _EventLoop.current._addMicrotaskCallback(callback);
      }
    }

    thread._pendingCallbackCount++;
    parent.scheduleMicrotask(zone, callback);
  }

  static Timer _createSystemTimer(
      Thread thread, Duration duration, Function function) {
    _log("createSystemTimer", function);
    _LinkedListEntry<_TimedCallback> entry;
    _isSystemTimer = true;
    var date = new DateTime.now().add(duration);
    void f() {
      _log("createSystemTimer f", function);
      return function();
    }

    var callback = new _ThreadCallback(thread, f);
    Timer timer;
    void action() {
      _log("createSystemTimer action", function);
      // TODO:
      thread._scheduledCallbackCount++;
      if (timer.isActive) {
        timer.cancel();
        //function();
        _EventLoop.current._addWakeupCallback(callback);
      } else {
        // TODO: Implement timer removal on cancel
        //throw null;
      }
    }

    timer = thread._zone.createTimer(duration, () {
      //thread._scheduledCallbackCount--;
      entry.unlink();
      //function();
      _EventLoop.current._addWakeupCallback(callback);
    });

    entry =
        new _LinkedListEntry<_TimedCallback>(new _TimedCallback(date, action));
    if (_timedCallbacks.isEmpty) {
      _timedCallbacks.add(entry);
    } else {
      var current = _timedCallbacks.last;
      var done = false;
      while (true) {
        if (current.element.date.compareTo(date) <= 0) {
          current.insertAfter(entry);
          done = true;
          break;
        }

        current = current.next;
        if (current == null) {
          break;
        }
      }

      if (!done) {
        _timedCallbacks.addFirst(entry);
      }
    }

    return timer;
  }

  static _processPendingZoneTasks() {
    if (_timedCallbacks.isEmpty) {
      return;
    }

    var now = new DateTime.now();
    var entry = _timedCallbacks.first;
    while (true) {
      var callback = entry.element;
      if (callback.date.compareTo(now) > 0) {
        break;
      }

      var next = entry.next;
      entry.unlink();
      entry = next;
      // TODO:
      Zone.root.runGuarded(callback.function);
      if (entry == null) {
        break;
      }
    }
  }

  static Map<int, int> _map = <int, int>{};
  static int _index = 0;

  static void _log(String message, Object o) {
    var i = _map[o.hashCode];
    if (i == null) {
      i = _index++;
      _map[o.hashCode] = i;
    }

    //print(new DateTime.now().toString() + ": " +  i.toString() + ": " + message + " " +  o.hashCode.toString());
  }
}
