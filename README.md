threading
=====

Threading is an implementation of the cooperative, non-preemptive multitasking (software threads). Also can be used in conjunction with any third-party libraries for parallel computations (for the coordination and synchronization).

Version: 0.0.4

**Initial release**

Examples:

[example/example_producer_consumer_problem.dart](https://github.com/mezoni/threading/blob/master/example/example_producer_consumer_problem.dart)

```dart
library threading.example.example_producer_consumer_problem;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  Future run() async {
    var length = 2;
    var buffer = new _BoundedBuffer(length);
    var total = length * 2;
    var consumed = 0;
    var produced = 0;
    var threads = <Thread>[];
    for (var i = 0; i < total; i++) {
      var thread = new Thread(() async {
        await buffer.put(i);
        print("${Thread.current.name}: => $i");
        produced++;
      });

      thread.name = "Producer $i";
      threads.add(thread);
      await thread.start();
    }

    for (var i = 0; i < total; i++) {
      var thread = new Thread(() async {
        var x = await buffer.take();
        print("${Thread.current.name}: <= $x");
        consumed++;
      });

      thread.name = "Consumer $i";
      threads.add(thread);
      await thread.start();
    }

    for (var thread in threads) {
      await thread.join();
    }

    print("Produced: $produced");
    print("Consumed: $consumed");
  }
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

  String toString() {
    return _items.sublist(0, _count).toString();
  }
}

```


[example/example_thread_interrupt_1.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_interrupt_1.dart)

```dart
library threading.example.example_thread_interrupt_1;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  bool _sleepSwitch = false;

  void set sleepSwitch(bool sleepSwitch) {
    _sleepSwitch = sleepSwitch;
  }

  Future run() async {
    var thread = new Thread(work);
    await thread.start();
    // The following line causes an exception to be thrown
    // in "work" if thread is currently blocked
    // or becomes blocked in the future.
    await thread.interrupt();
    print("Main thread calls interrupt on new thread.");
    // Tell newThread to go to sleep.
    sleepSwitch = true;
    // Wait for new thread to end.
    await thread.join();
  }

  Future work() async {
    print("Thread is executing 'work'.");
    while (!_sleepSwitch) {
      await Thread.sleep(0);
    }

    try {
      print("Thread going to sleep.");
      // When thread goes to sleep, it is immediately
      // woken up by a ThreadInterruptException.
      await Thread.sleep(-1);
    } on ThreadInterruptException catch (e) {
      print("Thread cannot go to sleep - interrupted by main thread.");
    }
  }
}

```

[example/example_thread_interrupt_2.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_interrupt_2.dart)

```dart
library threading.example.example_thread_interrupt_2;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  Future run() async {
    var t0 = new Thread(workAsync);
    var t1 = new Thread(workSync);
    await t0.start();
    await t1.start();
    await t0.join();
    await t1.join();
    print("Done");
  }

  Future workAsync() async {
    new Future(() {
      print("Future - should never be executed");
    });

    Timer.run(() {
      print("Timer - should never be executed");
    });

    throw new ThreadInterruptException();
  }

  void workSync() {
    new Future(() {
      print("Future - should never be executed");
    });

    Timer.run(() {
      print("Timer - should never be executed");
    });

    throw new ThreadInterruptException();
  }
}

```

[example/example_thread_join_1.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_join_1.dart)

```dart
library threading.example.example_thread_join_1;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  static final int waitTime = 1000;

  Future run() async {
    var thread = new Thread(work);
    await thread.start();
    if (await thread.join(waitTime * 2)) {
      print("New thread terminated.");
    } else {
      print("Join timed out.");
    }
  }

  static Future work() async {
    await Thread.sleep(waitTime);
  }
}

```

[example/example_thread_join_2.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_join_2.dart)

```dart
library threading.example.example_thread_join_2;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  Future run() async {
    var t1 = new Thread(() async {
      await Thread.sleep(2000);
      print("t1 is ending.");
    });

    t1.start();
    var t2 = new Thread(() async {
      await Thread.sleep(1000);
      print("t2 is ending.");
    });

    t2.start();
    await t1.join();
    print("t1.Join() returned.");
    await t2.join();
    print("t2.Join() returned.");
  }
}

```

[example/example_thread_timer_1.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_timer_1.dart)

```dart
library threading.example.example_thread_timer_1;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  Future run() async {
    var thread = new Thread(work);
    await thread.start();
    await thread.join();
    print("Thread terminated");
  }

  static Future work() async {
    var sw = new Stopwatch();
    await sw.start();
    new Timer(new Duration(milliseconds: 100), () {
      // This timer will sleep with thread
      print("Timer 100 ms, elapsed: ${sw.elapsedMilliseconds}");
    });

    new ThreadTimer(new Duration(milliseconds: 100), () {
      // This timer will be performed anyway
      print("ThreadTimer 100 ms, elapsed: ${sw.elapsedMilliseconds}");
    });

    print("Thread sleep");
    await Thread.sleep(1000);
    print("Thread wake up after 1000 ms, elapsed: ${sw.elapsedMilliseconds}");
    sw.stop();
  }
}

```
