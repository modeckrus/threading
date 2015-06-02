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
