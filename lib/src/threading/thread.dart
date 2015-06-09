part of threading;

typedef dynamic _UncaughtErrorHandler(Zone zone, Object error, StackTrace stackTrace);

/**
 * The [Thread] of execution is the smallest sequence of programmed
 * instructions that can be managed independently.
 *
 * This is an implementation of the cooperative (non-preemptive) multitasking
 * in a single isolate.
 * Once a thread is given control it continues to run until it explicitly
 * yields control or it blocks.
 */
class Thread {
  static Thread _current = _mainThread;

  static final Thread _mainThread = new Thread._main();

  static final DateTime _maxDateTime = new DateTime(9999, 12, 31, 23, 59, 59, 999);

  static Thread get current {
    return _current;
  }

  /**
   * The name of the [Thread].
   */
  String name;

  Completer _blocking;

  Function _computation;

  bool _isAbortInitiated = false;

  bool _isAbortRequested = false;

  bool _isInterruptRequested = false;

  // TODO: Remove
  bool _isYield = false;

  Thread _joinedThread;

  Set<Thread> _joinSet;

  ConditionVariable _monitor;

  int _pendingCallbackCount = 0;

  int _scheduledCallbackCount = 0;

  ThreadState _state;

  bool _timedOut;

  Set<Timer> _timers = new Set<Timer>();

  DateTime _wakeupTime;

  Timer _wakeupTimer;

  Zone _zone;

  // TODO:
  Thread(Function computation) {
    if (computation == null) {
      throw new ArgumentError.notNull("computation");
    }

    if (!(computation is ZoneCallback || computation is ZoneUnaryCallback)) {
      throw new ArgumentError.value(computation, "computation");
    }

    _computation = computation;
    _state = ThreadState.Unstarted;
    _zone = new _ZoneHandle(this).zone;
  }

  Thread._main() {
    _pendingCallbackCount++;
    _state = ThreadState.Active;
    _zone = new _ZoneHandle(this).zone;
  }

  /**
   * Indicates whether or not the thread was aborted.
   */
  bool get isAborted {
    switch (_state) {
      case ThreadState.Terminated:
        if (_isAbortRequested) {
          return true;
        }

        return false;
      default:
        return false;
    }
  }

  /**
   * Indicates whether or not the thread in a passive mode.
   */
  bool get isPassive {
    switch (_state) {
      case ThreadState.Joined:
      case ThreadState.Signaled:
      case ThreadState.Sleeping:
      case ThreadState.Syncing:
      case ThreadState.Waiting:
        return true;
      default:
        return false;
    }
  }

  /**
   * Indicates whether or not the thread is running.
   */
  bool get isRunning {
    switch (_state) {
      case ThreadState.Terminated:
      case ThreadState.Unstarted:
        return false;
      default:
        return true;
    }
  }

  /**
   * Returns the current state of the [Thread].
   */
  ThreadState get state {
    return _state;
  }

  /**
   * Initiates the abort of the [Thread].
   */
  Future abort() {
    _current._block();
    _current._abort(this);
    return _current._blocking.future;
  }

  /**
   * Initiates the interrupt of the [Thread].
   */
  Future interrupt() {
    _current._block();
    _current._interrupt(this);
    return _current._blocking.future;
  }

  /**
   * Joins the [Thread] and returns when the thread execution has completed.
   */
  Future<bool> join([int timeout]) {
    _current._block();
    _current._join(this, timeout);
    return _current._blocking.future;
  }

  /**
   * Initiates the execution of the [Thread].
   */
  Future start([Object parameter]) {
    _block();
    _start(parameter);
    return _blocking.future;
  }

  String toString() {
    if (name == null) {
      return "$runtimeType";
    }

    return "$runtimeType '$name'";
  }

  void _abort(Thread thread) {
    if (identical(thread, _mainThread)) {
      _failUp(new ThreadStateError("Unable to abort the main thread"));
    } else {
      if (!thread._isAbortRequested && !thread._isAbortInitiated) {
        thread._isAbortRequested = true;
      }

      if (thread.isPassive) {
        thread._abortOrInterruptPassive();
      }

      _yieldUp();
    }
  }

  void _abortOrInterruptPassive() {
    if (_isAbortRequested) {
      _injectException(new ThreadAbortException());
      _clearAbortRequest();
      _isAbortInitiated = true;
    } else if (_isInterruptRequested) {
      _injectException(new ThreadInterruptException());
      _isInterruptRequested = false;
    }
  }

  Future _acquire(ConditionVariable monitor) {
    _block();
    _acquire_(monitor);
    return _blocking.future;
  }

  void _acquire_(ConditionVariable monitor) {
    if (monitor == null) {
      _failUp(new ArgumentError.notNull("monitor"));
    } else if (monitor._lockOwner == this) {
      monitor._owner._lockCount[this]++;
      _yieldUp();
    } else if (monitor._lockOwner == null && monitor._readyQueue.isEmpty) {
      _lock(monitor);
      monitor._lockCount[this] = 1;
      _yieldUp();
    } else {
      _state = ThreadState.Syncing;
      _monitor = monitor;
      monitor._readyQueue.add(this);
    }
  }

  void _acquireLock(ConditionVariable monitor) {
    _lock(monitor);
    if (_state != ThreadState.Signaled) {
      monitor._lockCount[this] = 1;
    }

    _state = ThreadState.Active;
    monitor._readyQueue.removeFirst();
    if (_cancelWakeupTimer()) {
      _yieldUp(true);
    } else {
      // TODO:
      _yieldUp();
    }
  }

  void _addTimer(Timer timer) {
    _timers.add(timer);
  }

  void _block() {
    if (_blocking != null && !_blocking.isCompleted) {
      throw new ThreadStateError("Unable to block the thread");
    }

    _zone.run(() => _blocking = new Completer());
  }

  Future _broadcast(ConditionVariable monitor) {
    _block();
    _broadcast_(monitor);
    return _blocking.future;
  }

  void _broadcast_(ConditionVariable monitor) {
    if (monitor == null) {
      _failUp(new ArgumentError.notNull("monitor"));
    } else if (monitor._lockOwner != this) {
      _failUp(new SynchronizationException());
    } else {
      _state = ThreadState.Active;
      for (var thread in monitor._waitQueue) {
        thread._state == ThreadState.Signaled;
        monitor._readyQueue.add(thread);
      }

      monitor._waitQueue.clear();
      _yieldUp();
    }
  }

  bool _cancelWakeupTimer() {
    if (_wakeupTimer != null) {
      _wakeupTimer.cancel();
      _timers.remove(_wakeupTimer);
      _wakeupTimer = null;
      return true;
    }

    return false;
  }

  void _clearAbortRequest() {
    _isAbortRequested = false;
    _isInterruptRequested = false;
  }

  Thread _enter() {
    var previous = _current;
    _current = this;
    return previous;
  }

  void _executeActive(Function callback) {
    try {
      if (_isAbortRequested) {
        _clearAbortRequest();
        _isAbortInitiated = true;
        throw new ThreadAbortException();
      } else {
        callback();
      }
    } catch (error, stackTrace) {
      _zone.handleUncaughtError(error, stackTrace);
      return;
    }

    if (_state != ThreadState.Terminated && _state == ThreadState.Active) {
      if (_pendingCallbackCount == 0 && _scheduledCallbackCount == 0 && _timers.isEmpty) {
        _terminate();
      }
    }
  }

  void _fail(Object error) {
    _failUp(error);
    _block();
  }

  void _failUp(Object error) {
    // TODO: Remove
    //_isYield = true;
    try {
      throw error;
    } catch (error, stackTrace) {
      _blocking.completeError(error, stackTrace);
    }
  }

  dynamic _handleUncaughtError(Zone zone, Object error, StackTrace stackTrace, _UncaughtErrorHandler handleUncaughtError) {
    _terminate();
    if (!(error is ThreadAbortException || error is ThreadInterruptException)) {
      handleUncaughtError(zone, error, stackTrace);
    }

    return null;
  }

  void _init(Object parameter) {
    Function microtask;
    if (_computation is ZoneCallback) {
      microtask = _zone.bindCallback(_computation);
    } else {
      microtask = _zone.bindCallback(() => _computation(parameter));
    }

    _zone.scheduleMicrotask(microtask);
  }

  void _injectException(Object error) {
    _cancelWakeupTimer();
    _fail(error);
    switch (_state) {
      case ThreadState.Joined:
      case ThreadState.Sleeping:
      case ThreadState.Syncing:
        _state = ThreadState.Active;
        break;
      case ThreadState.Waiting:
        _moveToReadyQueue(_monitor);
        break;
      default:
        break;
    }
  }

  void _interrupt(Thread thread) {
    if (identical(thread, _mainThread)) {
      _failUp(new ThreadStateError("Unable to interrupt the main thread"));
    } else {
      if (!thread._isInterruptRequested) {
        thread._isInterruptRequested = true;
      }

      if (thread.isPassive) {
        thread._abortOrInterruptPassive();
      }

      _yieldUp();
    }
  }

  void _join(Thread thread, int timeout) {
    if (timeout != null && timeout < -1) {
      _failUp(new RangeError.value(timeout, "timeout"));
    } else if (_isInterruptRequested) {
      _throwInterruptException();
    } else if (thread._state == ThreadState.Terminated) {
      _yieldUp(true);
    } else {
      _state = ThreadState.Joined;
      _joinedThread = thread;
      if (thread._joinSet == null) {
        thread._joinSet = new Set<Thread>();
      }

      thread._joinSet.add(this);
      if (timeout != null) {
        _setupWakeupTimer(timeout);
      }
    }
  }

  void _joinReturn() {
    _cancelWakeupTimer();
    switch (_joinedThread._state) {
      case ThreadState.Terminated:
        _yieldUp(true);
        break;
      default:
        _yieldUp(false);
        break;
    }
  }

  void _leave(Thread previous) {
    _current = previous;
  }

  void _lock(ConditionVariable monitor) {
    monitor._lockOwner = this;
  }

  void _moveToReadyQueue(ConditionVariable cv) {
    cv._owner._readyQueue.add(this);
    cv._waitQueue.remove(this);
    _state = ThreadState.Signaled;
  }

  Future _release(ConditionVariable monitor) {
    _block();
    _release_(monitor);
    return _blocking.future;
  }

  void _release_(ConditionVariable monitor) {
    if (monitor == null) {
      throw new ArgumentError.notNull("monitor");
    } else if (monitor._lockOwner != this) {
      throw new SynchronizationException();
    } else {
      if (--monitor._lockCount[this] == 0) {
        _unlock(monitor);
        _releaseLock(monitor);
      }

      _yieldUp();
    }
  }

  void _releaseLock(ConditionVariable monitor) {
    var readyQueue = monitor._readyQueue;
    if (!readyQueue.isEmpty) {
      readyQueue.first._acquireLock(monitor);
    }
  }

  void _setupWakeupTimer(int timeout) {
    Duration duration;
    var now = new DateTime.now();
    if (timeout == -1) {
      duration = _maxDateTime.difference(now);
      _wakeupTime = _maxDateTime;
    } else {
      duration = new Duration(milliseconds: timeout);
      _wakeupTime = now.add(duration);
    }


    _wakeupTimer = _ZoneHandle._createSystemTimer(this, duration, _wakeup);
    //_wakeupTimer = new ThreadTimer(duration, _wakeup);
    _addTimer(_wakeupTimer);
  }

  Future _signal(ConditionVariable monitor) {
    _block();
    _signal_(monitor);
    return _blocking.future;
  }

  void _signal_(ConditionVariable monitor) {
    if (monitor == null) {
      _failUp(new ArgumentError.notNull("monitor"));
    } else if (monitor._owner._lockOwner != this) {
      _failUp(new SynchronizationException());
    } else {
      _state = ThreadState.Active;
      if (!monitor._waitQueue.isEmpty) {
        monitor._waitQueue.first._moveToReadyQueue(monitor);
      }

      _yieldUp();
    }
  }

  void _sleep(int timeout) {
    if (timeout == null) {
      _failUp(new ArgumentError.notNull("timeout"));
    } else if (timeout < -1) {
      _failUp(new RangeError.value(timeout, "timeout"));
    } else if (_isInterruptRequested) {
      _throwInterruptException();
    } else {
      _state = ThreadState.Sleeping;
      _setupWakeupTimer(timeout);
    }
  }

  void _start(Object parameter) {
    if (_state != ThreadState.Unstarted) {
      _failUp(new ThreadStateError("Unable to start the thread"));
    } else {
      if (_isAbortRequested) {
        _state = ThreadState.Terminated;
      } else {
        _state = ThreadState.Active;
        _init(parameter);
      }

      _yieldUp();
    }
  }

  void _terminate() {
    _state = ThreadState.Terminated;
    var timers = _timers.toList();
    _timers.clear();
    for (var timer in timers) {
      timer.cancel();
    }

    if (_joinSet != null) {
      for (var thread in _joinSet) {
        thread._state = ThreadState.Active;
        thread._joinReturn();
        thread._joinedThread = null;
      }

      _joinSet.clear();
    }
  }

  void _throwInterruptException() {
    _failUp(new ThreadInterruptException());
    _isInterruptRequested = false;
  }

  Future _tryAcquire(ConditionVariable monitor, int timeout) {
    _block();
    _tryAcquire_(monitor, timeout);
    return _blocking.future;
  }

  void _tryAcquire_(ConditionVariable monitor, int timeout) {
    if (monitor == null) {
      _failUp(new ArgumentError.notNull("monitor"));
    } else if (timeout != null && timeout < -1) {
      _failUp(new RangeError.value(timeout, "timeout"));
    } else if (monitor._lockOwner == this) {
      monitor._lockCount[this]++;
      _yieldUp(true);
    } else if (monitor._lockOwner == null && monitor._readyQueue.isEmpty) {
      _lock(monitor);
      monitor._lockCount[this] = 1;
      _yieldUp(true);
    } else if (timeout == null) {
      _yieldUp(false);
    } else {
      _state = ThreadState.Syncing;
      _monitor = monitor;
      monitor._readyQueue.add(this);
      _setupWakeupTimer(timeout);
    }
  }

  void _unlock(ConditionVariable monitor) {
    monitor._lockOwner = null;
  }

  Future _wait(ConditionVariable monitor, int timeout) {
    _block();
    _wait_(monitor, timeout);
    return _blocking.future;
  }

  void _wait_(ConditionVariable monitor, int timeout) {
    if (monitor == null) {
      _failUp(new ArgumentError.notNull("monitor"));
    } else if (timeout != null && timeout < -1) {
      _failUp(new RangeError.value(timeout, "timeout"));
    } else if (monitor._lockOwner != this) {
      _failUp(new SynchronizationException());
    } else if (_isInterruptRequested) {
      _throwInterruptException();
    } else {
      _state = ThreadState.Waiting;
      monitor._waitQueue.add(this);
      _monitor = monitor;
      _unlock(monitor);
      _releaseLock(monitor);
      _timedOut = false;
      if (timeout != null) {
        _setupWakeupTimer(timeout);
      }
    }
  }

  void _wakeup() {
    _timers.remove(_wakeupTimer);
    _wakeupTimer = null;
    switch (_state) {
      case ThreadState.Joined:
        _state = ThreadState.Active;
        _joinReturn();
        _joinedThread._joinSet.remove(this);
        _joinedThread = null;
        break;
      case ThreadState.Sleeping:
        _state = ThreadState.Active;
        _yieldUp();
        break;
      case ThreadState.Syncing:
        _state = ThreadState.Active;
        _monitor._readyQueue.remove(this);
        _monitor = null;
        _yieldUp(false);
        break;
      case ThreadState.Waiting:
        _moveToReadyQueue(_monitor);
        _monitor = null;
        // TODO:
        _timedOut = true;
        break;
      default:
        _failUp(new ThreadStateError());
        break;
    }
  }

  void _yieldUp([Object value]) {
    // TODO:
    //_isYield = true;
    _blocking.complete(value);
  }

  static Future sleep(int timeout) {
    _current._block();
    _current._sleep(timeout);
    return _current._blocking.future;
  }
}
