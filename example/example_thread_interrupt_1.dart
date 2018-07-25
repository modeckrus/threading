library threading.example.example_thread_interrupt_1;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  var isSpinWaitImplemented = false;
  if (!isSpinWaitImplemented) {
    print("This example was disabled because `spinWait` does not implemented");
    return;
  }

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
    // await Thread.spinWait(100000);
    await Thread.sleep(0);
  }

  try {
    print("Thread going to sleep.");
    // When thread goes to sleep, it is immediately
    // woken up by a ThreadInterruptException.
    await Thread.sleep(-1);
  } on ThreadInterruptException {
    print("Thread cannot go to sleep - interrupted by main thread.");
  }
}
