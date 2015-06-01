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
