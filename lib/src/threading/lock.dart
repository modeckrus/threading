part of threading;

/**
 * The [Lock] or mutex (from mutual exclusion) is a synchronization mechanism
 * for enforcing limits on access to a resource in an environment where there
 * are many threads of execution.
 */
class Lock {
  final Queue<Thread> _readyQueue = new Queue<Thread>();

  ConditionVariable _monitor;

  Map<Thread, int> _lockCount = <Thread, int>{};

  Thread _lockOwner;

  Lock() {
    _monitor = new ConditionVariable(this);
  }

  /**
   * Acquires the lock.
   */
  Future acquire() {
    return Thread._current._acquire(_monitor);
  }

  /**
   * Wakes up all waiting threads.
   */
  Future broadcast() {
    return Thread._current._broadcast(_monitor);
  }

  /**
   * Releases the lock.
   */
  Future release() {
    return Thread._current._release(_monitor);
  }

  /**
   * Wakes up one waiting thread.
   */
  Future signal() {
    return Thread._current._signal(_monitor);
  }

  /**
   * Attempts to acquire the lock.
   *
   * Parameters:
   *  [int] [timeout]
   *  The number of milliseconds to wait for the lock.
   */
  Future tryAcquire([int timeout]) {
    return Thread._current._tryAcquire(_monitor, timeout);
  }

  /**
   * Causes the current thread to wait until it is signalled or interrupted.
   */
  Future<bool> wait([int timeout]) {
    return Thread._current._wait(_monitor, timeout);
  }
}
