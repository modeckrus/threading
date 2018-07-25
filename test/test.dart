import "dart:async";
import "dart:io";

import 'package:threading/threading.dart';
import 'package:test/test.dart';

Future main() async {
  await testConditionVariable();
  await testLockAcquire();
  await testLockTryAcquire();
  await testLockWaitSignal();
  //await testThreadAbort();
  await testThreadInterrupt();
  await testThreadJoin();
  await testThreadSleep();
  await testThreadTimer();
  report();
}

int _failed = 0;

int _passed = 0;

void report() {
  var total = _passed + _failed;
  if (_passed != 0) {
    stdout.writeln("PASSED: $_passed from $total test(s)");
  }

  if (_failed != 0) {
    stdout.writeln("FAILED: $_failed from $total test(s)");
  }
}

Future testAsync(String name, f()) async => test(name, f);

Future testConditionVariable() async {
  await testAsync("Condition variable (many producers, one consumer)",
      () async {
    var length = 2;
    var buffer = new _BoundedBuffer(length);
    var total = length * 2;
    var consumed = 0;
    var produced = 0;
    var threads = <Thread>[];
    for (var i = 0; i < total; i++) {
      var thread = new Thread(() async {
        await buffer.put(i);
        produced++;
      });

      threads.add(thread);
      await thread.start();
    }

    var consumer = new Thread(() async {
      for (var i = 0; i < total; i++) {
        await buffer.take();
        consumed++;
      }
    });

    threads.add(consumer);
    await consumer.start();
    for (var thread in threads) {
      await thread.join();
    }

    expect(produced, total, reason: "Wrong number of produced items");
    expect(consumed, total, reason: "Wrong number of consumed items");
  });

  await testAsync("Condition variable (one producer, many consumers)",
      () async {
    var length = 2;
    var buffer = new _BoundedBuffer(length);
    var total = length * 2;
    var consumed = 0;
    var produced = 0;
    var threads = <Thread>[];
    for (var i = 0; i < total; i++) {
      var thread = new Thread(() async {
        await buffer.take();
        consumed++;
      });

      threads.add(thread);
      await thread.start();
    }

    var producer = new Thread(() async {
      for (var i = 0; i < total; i++) {
        await buffer.put(i);
        produced++;
      }
    });

    threads.add(producer);
    await producer.start();
    for (var thread in threads) {
      await thread.join();
    }

    expect(produced, total, reason: "Wrong number of produced items");
    expect(consumed, total, reason: "Wrong number of consumed items");
  });
}

Future testLockAcquire() async {
  await testAsync("Acquire lock", () async {
    var lock = new Lock();
    var value = 0;
    var fail = 0;
    Future work() async {
      await lock.acquire();
      try {
        value++;
        await Thread.sleep(0);
        if (--value != 0) {
          fail++;
        }
      } finally {
        await lock.release();
      }
    }

    var numberOfThreads = 1;
    var threads = <Thread>[];
    for (var i = 0; i < numberOfThreads; i++) {
      var thread = new Thread(work);
      threads.add(thread);
      await thread.start();
    }

    for (var i = 0; i < numberOfThreads; i++) {
      var thread = threads[i];
      await thread.join();
    }

    expect(fail, 0, reason: "Mutual exclusion is not working");
  });

  await testAsync("Acquire lock (recursive)", () async {
    var lock = new Lock();
    var value = 0;
    Future recursive() async {
      await lock.acquire();
      try {
        if (++value < 5) {
          await recursive();
        }
      } finally {
        await lock.release();
      }
    }

    Future work() async {
      recursive();
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.join();
    expect(value, 5, reason: "Value was not changed recursive");
  });
}

Future testLockTryAcquire() async {
  await testAsync("Try acquire lock", () async {
    var lock = new Lock();
    var value = 0;
    Future work1() async {
      await lock.acquire();
      try {
        value++;
        await Thread.sleep(500);
      } finally {
        await lock.release();
      }
    }

    Future work2() async {
      if (await lock.tryAcquire(1000)) {
        try {
          value++;
        } finally {
          await lock.release();
        }
      }
    }

    var t0 = new Thread(work1);
    var t1 = new Thread(work2);
    // TODO:
    t0.name = "t0";
    t1.name = "t1";
    await t0.start();
    await t1.start();
    await t0.join();
    await t1.join();
    expect(value, 2, reason: "Mutex was not acquired");
  });

  await testAsync("Try acquire lock (timed out)", () async {
    var lock = new Lock();
    var value = 0;
    Future work1() async {
      await lock.acquire();
      try {
        value++;
        await Thread.sleep(1000);
      } finally {
        await lock.release();
      }
    }

    Future work2() async {
      if (await lock.tryAcquire(500)) {
        try {
          value++;
        } finally {
          await lock.release();
        }
      }
    }

    var t0 = new Thread(work1);
    var t1 = new Thread(work2);
    await t0.start();
    await t1.start();
    await t0.join();
    await t1.join();
    expect(value, 1, reason: "Mutex was acquired");
  });
}

Future testLockWaitSignal() async {
  await testAsync("Wait signal", () async {
    var lock = new Lock();
    var go = false;
    var value = false;
    Future work() async {
      await lock.acquire();
      try {
        while (!go) {
          await lock.wait();
        }

        value = true;
      } finally {
        await lock.release();
      }
    }

    var t0 = new Thread(work);
    await t0.start();
    await Thread.sleep(100);
    await lock.acquire();
    try {
      go = true;
      await lock.signal();
    } finally {
      await lock.release();
    }

    await t0.join();
    expect(value, true, reason: "Value was not changed");
  });
}

Future testThreadAbort() async {
  await testAsync("Thread abort", () async {
    var thread = new Thread(() async {
      while (true) {
        await new Future.value();
      }
    });

    await thread.start();
    await Thread.sleep(100);
    await thread.abort();
    await thread.join();
    expect(thread.isAborted, true, reason: "Thread was not aborted");
  });
}

Future testThreadInterrupt() async {
  await testAsync("Interrupt thread with timer", () async {
    var value = false;
    Timer timer;
    Future work() async {
      timer = new Timer(new Duration(seconds: 1), () => value = true);
      await Thread.sleep(500);
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.interrupt();
    await t0.join();
    expect(value, false, reason: "Value was changed by timer");
    expect(timer.isActive, false, reason: "Timer still active");
  });

  await testAsync("Interrupt thread with periodic timer", () async {
    var value = false;
    Timer timer;
    Future work() async {
      timer = new Timer.periodic(
          new Duration(milliseconds: 100), (t) => value = true);
      while (true) {
        await Thread.sleep(500);
      }
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.interrupt();
    await t0.join();
    expect(value, false, reason: "Value was changed by timer");
    expect(timer.isActive, false, reason: "Timer still active");
  });

  await testAsync("Interrupt thread (catch ThreadInterruptException)",
      () async {
    var value = 0;
    ThreadInterruptException exception;
    Future work() async {
      try {
        value++;
        await Thread.sleep(500);
      } on ThreadInterruptException catch (e) {
        exception = e;
      }

      value++;
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.interrupt();
    await t0.join();
    expect(value, 2, reason: "Thread was interrupted");
    expect(exception is ThreadInterruptException, true,
        reason: "ThreadInterruptException was not catched");
  });

  await testAsync("Interrupt thread (itself)", () async {
    var value = false;
    Future work() async {
      await Thread.current.interrupt();
      await Thread.sleep(500);
      value = true;
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.join();
    expect(value, false, reason: "Value was changed");
  });

  await testAsync("Interrupt passive thread", () async {
    var value = false;
    ThreadState state;
    Future work() async {
      try {
        // Sleep infinitely
        await Thread.sleep(-1);
      } on ThreadInterruptException {
        value = true;
      }
    }

    var t0 = new Thread(work);
    await t0.start();
    await Thread.sleep(100);
    state = t0.state;
    await t0.interrupt();
    await t0.join();
    expect(value, true, reason: "Value not was changed");
    expect(state, ThreadState.Sleeping,
        reason: "Thead was not in passive state");
  });
}

Future testThreadJoin() async {
  await testAsync("Join thread with timer", () async {
    var value = false;
    void work() {
      Timer.run(() => value = true);
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.join();
    expect(value, true, reason: "Value was not changed by timer");
  });

  await testAsync("Join thread with microtask", () async {
    var value = false;
    void work() {
      scheduleMicrotask(() => value = true);
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.join();
    expect(value, true, reason: "Value was not changed by microtask");
  });

  await testAsync("Join with timeout", () async {
    var value = false;
    Future work() async {
      await Thread.sleep(500);
      value = true;
    }

    var t0 = new Thread(work);
    await t0.start();
    if (await t0.join(200)) {
      expect(value, true, reason: "Value was not changed by microtask");
      expect(false, true, reason: "Joined thread terminated too early");
    } else {
      expect(value, false, reason: "Value was changed by microtask");
    }
  });
}

Future testThreadSleep() async {
  await testAsync("Sleep thread", () async {
    var count = 10;
    var value = 0;
    Future work() async {
      for (; value < count; value++) {
        await Thread.sleep(0);
      }
    }

    var numberOfThreads = 5;
    var threads = <Thread>[];
    for (var i = 0; i < numberOfThreads; i++) {
      var thread = new Thread(work);
      threads.add(thread);
      await thread.start();
    }

    for (var i = 0; i < numberOfThreads; i++) {
      var thread = threads[i];
      thread.name = "t$i";
      await thread.join();
    }

    expect(value, count + numberOfThreads - 1,
        reason: "Incorrect number of iterations");
  });

  await testAsync("Sleep thread (sleep in timers)", () async {
    var value = 0;
    Future work() async {
      Timer.run(() async {
        await Thread.sleep(100);
        value++;
      });

      Timer.run(() async {
        await Thread.sleep(100);
        value++;
      });
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.join();
    expect(value, 2, reason: "Value was not changed by timers");
  });
}

Future testThreadTimer() async {
  await testAsync("Thread timer", () async {
    var value = false;
    Future work() async {
      new ThreadTimer(new Duration(milliseconds: 500), () => value = true);
    }

    var t0 = new Thread(work);
    await t0.start();
    await t0.join();
    expect(value, false, reason: "Value was changed by thread timer");
    await Thread.sleep(1000);
    expect(value, true, reason: "Value was not changed by thread timer");
  });
}

class _BoundedBuffer<T> {
  final int length;

  int _count = 0;

  List<T> _items;

  final Lock _lock = new Lock();

  ConditionVariable _notEmpty;

  ConditionVariable _notFull;

  int _putptr = 0;

  int _takeptr = 0;

  _BoundedBuffer(this.length) {
    _items = new List<T>(length);
    _notFull = new ConditionVariable(_lock);
    _notEmpty = new ConditionVariable(_lock);
  }

  Future put(T x) async {
    await _lock.acquire();
    try {
      while (_count == _items.length) {
        await _notFull.wait();
      }

      _items[_putptr] = x;
      if (++_putptr == _items.length) {
        _putptr = 0;
      }

      ++_count;
      await _notEmpty.signal();
    } finally {
      await _lock.release();
    }
  }

  Future<T> take() async {
    await _lock.acquire();
    try {
      while (_count == 0) {
        await _notEmpty.wait();
      }

      var x = _items[_takeptr];
      if (++_takeptr == _items.length) {
        _takeptr = 0;
      }

      --_count;
      await _notFull.signal();
      return x;
    } finally {
      await _lock.release();
    }
  }
}
