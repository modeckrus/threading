library threading.example.example_producer_consumer_problem;

import "dart:async";
import "dart:collection";

import "package:threading/threading.dart";

Future main() async {
  await testThreads();
  await testFutures();
}

void printWithIndent(int indent, String text) {
  print("-" * indent++ + text);
}

Future testThreads() async {
  print("================================");
  print("Test Threads");
  print("--------------------------------");
  var length = 4;
  var buffer = new _BoundedBuffer(length);
  var total = length * 2;
  var consumed = 0;
  var produced = 0;
  var threads = <Thread>[];
  var item = 0;
  var indent = 0;
  var loop = 3;
  for (var i = 0; i < total; i++) {
    var thread = new Thread(() async {
      var name = "Producer $i";
      for (var j = 0; j < loop; j++) {
        printWithIndent(indent++, "$name: produce item (start)");
        item++;
        await wait(500);
        printWithIndent(--indent, "$name: produce item (done) $item");
        var x = item++;
        printWithIndent(indent++, "$name: add item (start) $item");
        await buffer.put(x);
        printWithIndent(--indent, "$name: add item (done) $item");
        produced++;
        await Thread.sleep(0);
      }
    });

    threads.add(thread);
    await thread.start();
  }

  for (var i = 0; i < total; i++) {
    var thread = new Thread(() async {
      var name = "Consumer $i";
      for (var j = 0; j < loop; j++) {
        printWithIndent(indent++, "$name: take item (start)");
        var x = await buffer.take();
        printWithIndent(--indent, "$name: take item (done) $x");
        printWithIndent(indent++, "$name: consume item (start) $x");
        await wait(500);
        printWithIndent(--indent, "$name: consume item (done) $x");
        consumed++;
        await Thread.sleep(0);
      }
    });

    threads.add(thread);
    await thread.start();
  }

  await Thread.sleep(0);
  var sw = new Stopwatch();
  sw.start();
  for (var thread in threads) {
    await thread.join();
  }

  sw.stop();
  print("Elapsed: ${sw.elapsedMilliseconds} msec");

  print("Produced: $produced");
  print("Consumed: $consumed");
}

Future testFutures() async {
  print("================================");
  print("Test Futures");
  print("--------------------------------");
  var length = 4;
  var buffer = new BoundedAsyncBuffer(length);
  var total = length * 2;
  var consumed = 0;
  var produced = 0;
  var futures = <Future>[];
  var item = 0;
  var indent = 0;
  var loop = 3;
  for (var i = 0; i < total; i++) {
    var future = new Future(() async {
      var name = "Producer $i";
      for (var j = 0; j < loop; j++) {
        printWithIndent(indent++, "$name: produce item (start)");
        item++;
        await wait(500);
        printWithIndent(--indent, "$name: produce item (done) $item");
        var x = item++;
        printWithIndent(indent++, "$name: add item (start) $item");
        await buffer.add(x);
        printWithIndent(--indent, "$name: add item (done) $item");
        produced++;
      }
    });

    futures.add(future);
  }

  for (var i = 0; i < total; i++) {
    var future = new Future(() async {
      var name = "Consumer $i";
      for (var j = 0; j < loop; j++) {
        printWithIndent(indent++, "$name: take item (start)");
        var x = await buffer.remove();
        printWithIndent(--indent, "$name: take item (done) $x");
        printWithIndent(indent++, "$name: consume item (start) $x");
        await wait(500);
        printWithIndent(--indent, "$name: consume item (done) $x");
        consumed++;
      }
    });

    futures.add(future);
  }

  var sw = new Stopwatch();
  sw.start();
  await Future.wait(futures);
  sw.stop();
  print("Elapsed: ${sw.elapsedMilliseconds} msec");

  print("Produced: $produced");
  print("Consumed: $consumed");
}

Future wait(int msec) {
  var completer = new Completer();
  new Timer(new Duration(milliseconds: 500), () {
    completer.complete();
  });

  return completer.future;
}

class BoundedAsyncBuffer<T> {
  // State is one of:
  // - one or more readers waiting, no elements in queue.
  // - between zero and capacity - 1 element in queue
  // - capacity - 1 + n elements in queue, n producers waiting.
  final int _capacity;
  final Queue _buffer = new Queue(); // unconsumed elements.
  final Queue _waiting = new Queue(); // producers or consumers.
  BoundedAsyncBuffer(int capacity) : _capacity = capacity;
  Future add(T element) {
    if (_buffer.isEmpty && _waiting.isNotEmpty) {
      _waiting.removeFirst().complete(element);
      return new Future.value();
    }
    _buffer.add(element);
    if (_buffer.length >= _capacity) {
      var c = new Completer();
      _waiting.add(c);
      return c.future;
    }
    return new Future.value();
  }

  Future<T> remove() {
    if (_buffer.isEmpty) {
      var c = new Completer<T>();
      _waiting.add(c);
      return c.future;
    }
    var result = _buffer.removeFirst();
    if (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete();
    }
    return new Future.value(result);
  }
}

class _BoundedBuffer<T> {
  final int length;

  int _count = 0;

  List<T> _items;

  final Lock _lock = new Lock();

  ConditionVariable _notEmpty;

  ConditionVariable _notFull;

  int _putptr = 0;

  int _takeptr = 0;

  _BoundedBuffer(this.length) {
    _items = new List<T>(length);
    _notFull = new ConditionVariable(_lock);
    _notEmpty = new ConditionVariable(_lock);
  }

  Future put(T x) async {
    await _lock.acquire();
    try {
      while (_count == _items.length) {
        await _notFull.wait();
      }

      _items[_putptr] = x;
      if (++_putptr == _items.length) {
        _putptr = 0;
      }

      ++_count;
      await _notEmpty.signal();
    } finally {
      await _lock.release();
    }
  }

  Future<T> take() async {
    await _lock.acquire();
    try {
      while (_count == 0) {
        await _notEmpty.wait();
      }

      var x = _items[_takeptr];
      if (++_takeptr == _items.length) {
        _takeptr = 0;
      }

      --_count;
      await _notFull.signal();
      return x;
    } finally {
      await _lock.release();
    }
  }

  String toString() {
    return _items.sublist(0, _count).toString();
  }
}
