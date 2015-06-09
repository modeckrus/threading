threading
=====

Threading is an implementation of the cooperative, non-preemptive multitasking (software threads). Also can be used in conjunction with any third-party libraries for parallel computations (for the coordination and synchronization).

Version: 0.0.8

**Initial release**

Threading package is an implementation of the software threads.  
Software threads executed in a single isolate and at the same time provides  
behavior of the standard threads.  
They can be called as a software emulation because they does not executed in  
preemptive mode.  
But on the other hand, they have only two limitations:  

- Executed in a single isolate
- Does not switches the context by the hardware interrupt

In all other cases they are works like the normal threads executed on an  
uniprocessor system in cooperative mode.  

**Features**

- Sleep, join and interrupt threads
- Acquire, release locks
- Wait, signal and broadcast by condition variables  

**Examples:**

[example/example_interleaved_execution.dart](https://github.com/mezoni/threading/blob/master/example/example_interleaved_execution.dart)

```dart
library threading.example.example_interleaved_execution;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await runFutures();
  await runThreads();
}

Future runFutures() async {
  print("Futures (linear execution)");
  print("----------------");
  var futures = <Future>[];
  var numOfFutures = 3;
  var count = 3;
  for (var i = 0; i < numOfFutures; i++) {
    var name = new String.fromCharCode(65 + i);
    var thread = new Future(() async {
      for (var j = 0; j < count; j++) {
        await new Future.value();
        print("$name: $j");
      }
    });

    futures.add(thread);
  }

  await Future.wait(futures);
}

Future runThreads() async {
  print("Threads (interleaved execution)");
  print("----------------");
  var threads = <Thread>[];
  var numOfThreads = 3;
  var count = 3;
  for (var i = 0; i < numOfThreads; i++) {
    var name = new String.fromCharCode(65 + i);
    var thread = new Thread(() async {
      for (var j = 0; j < count; j++) {
        await new Future.value();
        print("$name: $j");
      }
    });

    threads.add(thread);
    await thread.start();
  }

  for (var i = 0; i < numOfThreads; i++) {
    await threads[i].join();
  }
}
```

Output:

```
Futures (linear execution)
----------------
A: 0
A: 1
A: 2
B: 0
B: 1
B: 2
C: 0
C: 1
C: 2
Threads (interleaved execution)
----------------
A: 0
A: 1
B: 0
A: 2
B: 1
C: 0
B: 2
C: 1
C: 2
```

[example/example_producer_consumer_problem.dart](https://github.com/mezoni/threading/blob/master/example/example_producer_consumer_problem.dart)

```dart
library threading.example.example_producer_consumer_problem;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
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

Output:

```
Producer 0: => 0
Producer 1: => 1
Consumer 0: <= 0
Consumer 1: <= 1
Producer 2: => 2
Consumer 3: <= 2
Producer 3: => 3
Consumer 2: <= 3
Produced: 4
Consumed: 4
```

[example/example_thread_join_1.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_join_1.dart)

```dart
library threading.example.example_thread_join_1;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  var thread = new Thread(work);
  await thread.start();
  if (await thread.join(_waitTime * 2)) {
    print("New thread terminated.");
  } else {
    print("Join timed out.");
  }
}

final int _waitTime = 1000;

Future work() async {
  await Thread.sleep(_waitTime);
}

```

Output:

```
New thread terminated.
```

[example/example_thread_timer_1.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_timer_1.dart)

```dart
library threading.example.example_thread_timer_1;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  var thread = new Thread(work);
  await thread.start();
  await thread.join();
  print("Thread terminated");
}

Future work() async {
  var sw = new Stopwatch();
  await sw.start();
  for (var i = 0; i < 2; i++) {
    new Timer(new Duration(milliseconds: 100), () {
      // This timer will sleep with thread
      print("Timer 100 ms, elapsed: ${sw.elapsedMilliseconds}");
    });

    new ThreadTimer(new Duration(milliseconds: 100), () {
      // This timer will be performed anyway
      print("ThreadTimer 100 ms, elapsed: ${sw.elapsedMilliseconds}");
    });
  }

  print("Thread sleep");
  await Thread.sleep(1000);
  print("Thread wake up after 1000 ms, elapsed: ${sw.elapsedMilliseconds}");
  sw.stop();
}
```

Output:

```
Thread sleep
ThreadTimer 100 ms, elapsed: 111
ThreadTimer 100 ms, elapsed: 114
Thread wake up after 1000 ms, elapsed: 1008
Timer 100 ms, elapsed: 1008
Timer 100 ms, elapsed: 1008
Thread terminated
```

[example/example_thread_interrupt_2.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_interrupt_2.dart)

```dart
library threading.example.example_thread_interrupt_2;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  var t0 = new Thread(workAsync);
  //var t1 = new Thread(workSync);
  await t0.start();
  //await t1.start();
  await t0.join();
  //await t1.join();
  print("Done");
}

Future workAsync() async {
  new Future(() {
    print("Async: Future - should never be executed");
  });

  Timer.run(() {
    print("Async: Timer - should never be executed");
  });

  throw new ThreadInterruptException();
}

void workSync() {
  new Future(() {
    print("Sync: Future - should never be executed");
  });

  Timer.run(() {
    print("Sync: Timer - should never be executed");
  });

  throw new ThreadInterruptException();
}
```

Output:

```
Done
```

[example/example_thread_interrupt_1.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_interrupt_1.dart)

```dart
library threading.example.example_thread_interrupt_1;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  var thread = new Thread(work);
  await thread.start();
  // The following line causes an exception to be thrown
  // in "work" if thread is currently blocked
  // or becomes blocked in the future.
  await thread.interrupt();
  print("Main thread calls interrupt on new thread.");
  // Tell newThread to go to sleep.
  _sleepSwitch = true;
  // Wait for new thread to end.
  await thread.join();
}

bool _sleepSwitch = false;

Future work() async {
  print("Thread is executing 'work'.");
  while (!_sleepSwitch) {
    print("work");
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
```

Output:

```
Thread is executing 'work'.
work
Main thread calls interrupt on new thread.
```

[example/example_thread_join_2.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_join_2.dart)

```dart
library threading.example.example_thread_join_2;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
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
```

Output:

```
t2 is ending.
t1 is ending.
t1.Join() returned.
t2.Join() returned.
```

[example/example_thread_interrupt_3.dart](https://github.com/mezoni/threading/blob/master/example/example_thread_interrupt_3.dart)

```dart
library threading.example.example_thread_interrupt_3;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  print("Main thread starting");
  var secondThread = new Thread(threadJob);
  await secondThread.start();
  print("Main thread sleeping");
  await Thread.sleep(500);
  await _lock.acquire();
  try {
    print("Main thread acquired lock - signaling monitor");
    await _lock.signal();
    print("Monitor signaled; interrupting second thread");
    await secondThread.interrupt();
    await Thread.sleep(1000);
    print("Main thread still owns lock...");
  } finally {
    await _lock.release();
  }
}

Lock _lock = new Lock();

Future threadJob() async {
  print("Second thread starting");
  await _lock.acquire();
  try {
    print("Second thread acquired lock - about to wait");
    try {
      await _lock.wait();
    } catch (e) {
      print("Second thread caught an exception: $e");
    }
  } finally {
    await _lock.release();
  }
}
```

Output:

```
Main thread starting
Main thread sleeping
Second thread starting
Second thread acquired lock - about to wait
Main thread acquired lock - signaling monitor
Monitor signaled; interrupting second thread
Main thread still owns lock...
Second thread caught an exception: ThreadInterruptException
```

