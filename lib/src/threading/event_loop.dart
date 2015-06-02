part of threading;

class _EventLoop {
  static final _EventLoop current = new _EventLoop();

  LinkedList<_LinkedListEntry<_ThreadCallback>> microtaskQueue = new LinkedList<_LinkedListEntry<_ThreadCallback>>();

  LinkedList<_LinkedListEntry<_ThreadCallback>> timerQueue = new LinkedList<_LinkedListEntry<_ThreadCallback>>();

  LinkedList<_LinkedListEntry<_ThreadCallback>> wakeupQueue = new LinkedList<_LinkedListEntry<_ThreadCallback>>();

  bool _isScheduled = false;

  void loop() {
    _isScheduled = false;
    var done = false;
    _LinkedListEntry<_ThreadCallback> entry;
    var isProductive = false;
    for (var step = 0; step < 3; step++) {
      LinkedList queue;
      switch (step) {
        case 0:
          queue = wakeupQueue;
          break;
        case 1:
          queue = microtaskQueue;
          break;
        case 2:
          queue = timerQueue;
          break;
      }

      if (queue.isEmpty) {
        continue;
      }

      entry = queue.first;
      while (true) {
        var callback = entry.element;
        var thread = callback.thread;
        if (thread._state == ThreadState.Active) {
          entry.unlink();
          thread._scheduledCallbackCount--;
          thread._executeActive(callback.function);
          done = true;
          isProductive = true;
          break;
        } else if (thread._state == ThreadState.Terminated) {
          var next = entry.next;
          entry.unlink();
          entry = next;
        } else {
          entry = entry.next;
        }

        if (entry == null) {
          break;
        }
      }

      if (done) {
        break;
      }
    }

    if (isProductive) {
      if (!microtaskQueue.isEmpty || !timerQueue.isEmpty || !wakeupQueue.isEmpty) {
        schedule();
      }
    }
  }

  void schedule() {
    if (_isScheduled) {
      return;
    }

    _isScheduled = true;
    Zone.ROOT.scheduleMicrotask(loop);
  }

  void _addMicrotaskCallback(_ThreadCallback callback) {
    var entry = new _LinkedListEntry<_ThreadCallback>(callback);
    microtaskQueue.add(entry);
    schedule();
  }

  void _addTimerCallback(_ThreadCallback callback) {
    var entry = new _LinkedListEntry<_ThreadCallback>(callback);
    timerQueue.add(entry);
    schedule();
  }

  void _addWakeupCallback(_ThreadCallback callback) {
    var entry = new _LinkedListEntry<_ThreadCallback>(callback);
    wakeupQueue.add(entry);
    schedule();
  }
}
