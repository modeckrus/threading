library threading.example.example_thread_join_2;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  var t1 = new Thread(() async {
    await Thread.sleep(2000);
    print("t1 is ending.");
  });

  await t1.start();
  var t2 = new Thread(() async {
    await Thread.sleep(1000);
    print("t2 is ending.");
  });

  await t2.start();
  await t1.join();
  print("t1.Join() returned.");
  await t2.join();
  print("t2.Join() returned.");
}
