threading
=====

This is the implementation of the cooperative, non-preemptive multitasking (software threads). Also can be used in conjunction with any third-party libraries for parallel computations (for the coordination and synchronization).

Version: 0.0.1

**Initial release**

Examples:

**example/example_thread_interrupt_1.dart**

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

**example/example_thread_interrupt_2.dart**

```dart
library threading.example.example_thread_interrupt_2;

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
**example/example_thread_join_1.dart**

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

**example/example_thread_join_2.dart**

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

**example/example_thread_timer_1.dart**

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
