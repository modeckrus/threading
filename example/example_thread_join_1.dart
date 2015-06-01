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
