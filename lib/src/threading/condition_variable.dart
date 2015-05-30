part of threading;

/**
 * The [ConditionVariable] is basically a container of threads that are waiting
 * on a certain condition.
 */
class ConditionVariable {
  final Lock _owner;

  final Queue<Thread> _waitQueue = new Queue<Thread>();

  ConditionVariable(Lock lock) : this._owner = lock {
    if (lock == null) {
      throw new ArgumentError.notNull("lock");
    }
  }

  Map<Thread, int> get _lockCount {
    return _owner._lockCount;
  }

  Thread get _lockOwner {
    return _owner._lockOwner;
  }

  void set _lockOwner(Thread owner) {
    _owner._lockOwner = owner;
  }

  Queue<Thread> get _readyQueue {
    return _owner._readyQueue;
  }

  /**
   * Wakes up all waiting threads.
   */
  Future broadcast() {
    return Thread._current._broadcast(this);
  }

  /**
   * Wakes up one waiting thread.
   */
  Future signal() {
    return Thread._current._signal(this);
  }

  /**
   * Causes the current thread to wait until it is signalled or interrupted.
   */
  Future<bool> wait([int timeout]) {
    return Thread._current._wait(this, timeout);
  }
}
