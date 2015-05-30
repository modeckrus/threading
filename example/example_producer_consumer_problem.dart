library threading.example.example_producer_consumer_problem;

import "dart:async";

import "package:threading/threading.dart";

Future main() async {
  await new Example().run();
}

class Example {
  Future run() async {
    var length = 2;
    var buffer = new _BoundedBuffer(length);
    var total = length * 2;
    var consumed = 0;
    var produced = 0;
    var threads = <Thread>[];
    for (var i = 0; i < total; i++) {
      var thread = new Thread(() async {
        await buffer.put(i);
        print("${Thread.current.name}: => $i");
        produced++;
      });

      thread.name = "Producer $i";
      threads.add(thread);
      await thread.start();
    }

    for (var i = 0; i < total; i++) {
      var thread = new Thread(() async {
        var x = await buffer.take();
        print("${Thread.current.name}: <= $x");
        consumed++;
      });

      thread.name = "Consumer $i";
      threads.add(thread);
      await thread.start();
    }

    for (var thread in threads) {
      await thread.join();
    }

    print("Produced: $produced");
    print("Consumed: $consumed");
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
