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
