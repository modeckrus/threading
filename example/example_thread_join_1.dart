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
