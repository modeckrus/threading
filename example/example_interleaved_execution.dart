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
