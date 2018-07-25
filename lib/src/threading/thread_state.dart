part of threading;

/**
 * The [ThreadState] specifies the execution states of a [Thread].
 */
enum ThreadState {
  Active,
  Joined,
  Signaled,
  Sleeping,
  Syncing,
  Terminated,
  Unstarted,
  Waiting
}
