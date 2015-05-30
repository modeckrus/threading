library threading.example.example_thread_interrupt_3;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  Lock someLock = new Lock();

  Future run() async {
    Thread.current.name = "main";
    print("Main thread starting");
    var secondThread = new Thread(threadJob);
    secondThread.name = "secondThread";
    await secondThread.start();
    print("Main thread sleeping");
    await Thread.sleep(500);
    await someLock.acquire();
    try {
      print("Main thread acquired lock - signaling monitor");
      await someLock.signal();
      print("Monitor signaled; interrupting second thread");
      await secondThread.interrupt();
      await Thread.sleep(1000);
      print("Main thread still owns lock...");
    } finally {
      await someLock.release();
    }
  }

  Future threadJob() async {
    print("Second thread starting");
    await someLock.acquire();
    try {
      print("Second thread acquired lock - about to wait");
      try {
        await someLock.wait();
      } catch (e) {
        print("Second thread caught an exception: $e");
      }
    } finally {
      await someLock.release();
    }
  }
}
