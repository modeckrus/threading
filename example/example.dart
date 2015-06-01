library threading.example.example;

import "dart:async";

import "example_interleaved_execution.dart" as example_interleaved_execution;
import "example_producer_consumer_problem.dart" as example_producer_consumer_problem;
import "example_thread_interrupt_1.dart" as example_thread_interrupt_1;
import "example_thread_interrupt_2.dart" as example_thread_interrupt_2;
import "example_thread_interrupt_3.dart" as example_thread_interrupt_3;
import "example_thread_join_1.dart" as example_thread_join_1;
import "example_thread_join_2.dart" as example_thread_join_2;
import "example_thread_timer_1.dart" as example_thread_timer_1;

Future main() async {
  await runExample("Example: Interleaved Execution", example_interleaved_execution.main);
  await runExample("Example: Producer-consumer problem", example_producer_consumer_problem.main);
  await runExample("Example: Thread Interrupt 1", example_thread_interrupt_1.main);
  await runExample("Example: Thread Interrupt 2", example_thread_interrupt_2.main);
  await runExample("Example: Thread Interrupt 3", example_thread_interrupt_3.main);
  await runExample("Example: Thread Join 1", example_thread_join_1.main);
  await runExample("Example: Thread Join 2", example_thread_join_2.main);
  await runExample("Example: Thread Timer 1", example_thread_timer_1.main);
}

Future runExample(String name, Future example()) async {
  print("================");
  print(name);
  print("----------------");
  await example();
}
