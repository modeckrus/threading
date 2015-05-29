library threading.example.example;

import "dart:async";

import "example_thread_interrupt_1.dart" as example_thread_interrupt_1;
import "example_thread_interrupt_2.dart" as example_thread_interrupt_2;
import "example_thread_join_1.dart" as example_thread_join_1;
import "example_thread_join_2.dart" as example_thread_join_2;
import "example_thread_timer_1.dart" as example_thread_timer_1;

Future main() async {
  await runExample("Example: Thread Interrupt 1", example_thread_interrupt_1.main);
  await runExample("Example: Thread Interrupt 2", example_thread_interrupt_2.main);
  await runExample("Example: Thread Join 1", example_thread_join_1.main);
  await runExample("Example: Thread Join 2", example_thread_join_2.main);
  await runExample("Example: Thread Timer 1", example_thread_timer_1.main);}

Future runExample(String name, Future example()) async {
  print("================");
  print(name);
  print("================");
  await example();
}
