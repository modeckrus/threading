part of threading;

class _ZoneHandle {
  final Thread thread;

  Zone zone;

  _ZoneHandle(this.thread) {
    if (thread == null) {
      throw new ArgumentError.notNull("thread");
    }

    zone = Zone.ROOT.fork(specification: _createSpecification());
  }

  Timer _createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone, Duration period, void f(Timer timer)) {
    void callback(Timer timer) {
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

  Timer _createTimer(Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f()) {
    Timer timer;
    void callback() {
      thread._pendingCallbackCount--;
      thread._scheduledCallbackCount++;
      thread._timers.remove(timer);
      var callback = new _ThreadCallback(thread, f);
      _EventLoop.current._addTimerCallback(callback);
    }

    timer = parent.createTimer(zone, duration, callback);
    timer = new _Timer(thread, timer);
    thread._pendingCallbackCount++;
    thread._timers.add(timer);
    return timer;
  }

  AsyncError _errorCallback(Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) {
    return parent.errorCallback(zone, error, stackTrace);
  }

  Zone _fork(Zone self, ZoneDelegate parent, Zone zone, ZoneSpecification specification, Map zoneValues) {
    return parent.fork(Zone.ROOT, specification, zoneValues);
  }

  dynamic _handleUncaughtError(Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) {
    return thread._handleUncaughtError(zone, error, stackTrace, parent.handleUncaughtError);
  }

  void _print(Zone self, ZoneDelegate parent, Zone zone, String line) {
    parent.print(zone, line);
  }

  ZoneBinaryCallback _registerBinaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(Object arg1, Object arg2)) {
    dynamic callback(Object arg1, Object arg2) {
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

  ZoneCallback _registerCallback(Zone self, ZoneDelegate parent, Zone zone, f()) {
    dynamic callback() {
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

  ZoneUnaryCallback _registerUnaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(Object arg)) {
    dynamic callback(Object arg) {
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

  // TODO: remove
  dynamic _run(Zone self, ZoneDelegate parent, Zone zone, f()) {
    return parent.run(zone, f);
  }

  // TODO: remove
  dynamic _runBinary(Zone self, ZoneDelegate parent, Zone zone, f(Object arg1, Object arg2), Object arg1, Object arg2) {
    return parent.runBinary(zone, f, arg1, arg2);
  }

  // TODO: remove
  dynamic _runUnary(Zone self, ZoneDelegate parent, Zone zone, f(Object arg), Object arg) {
    return parent.runUnary(zone, f, arg);
  }

  void _scheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()) {
    void callback() {
      thread._pendingCallbackCount--;
      thread._scheduledCallbackCount++;
      var callback = new _ThreadCallback(thread, f);
      _EventLoop.current._addMicrotaskCallback(callback);
    }

    thread._pendingCallbackCount++;
    return parent.scheduleMicrotask(zone, callback);
  }
}
