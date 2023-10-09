## Applications of Algebraic Data Types

We seen some examples of algebraic data types already. Some of the simplest are the basic enumeration, like

```scala mdoc:silent
enum Permissions {
  case User
  case Moderator
  case Admin
}
```

and our old friend the `case class`

```scala mdoc:silent
final case class Uri(protocol: String, host: String, port: Int, path: String)
```

Those new to algebraic data types often don't realise how many other uses cases there are.
We'll see combinator libraries, an extremely important use, in the next chapter.
Here I want to give a few examples of finite state machines as another use case.

Finite state machines occur everywhere in programming. The state of a user interface component, such as open or closed, or visible or invisible, can be modelled as a finite state machine. That's probably not relevant to most Scala programmers, so let's consider instead a distributed job server. The idea is here that users submit jobs to run on a cluster of computers. The supervisor is responsible for selecting a computer on which to run the job, monitoring it, and collecting the result on successful completion.

In a very simple system we might represent jobs as having four states:

1. Queued: the job is in the queue to be run.
2. Running: the job is running on a computer.
3. Completed: the job successfully finished and we have collected the result.
4. Failed: the job failed to run to completion.

When using an algebraic data type we're not restricted to a simple enumeration of states.
We can also store data within the states.
So, in our job control system, we could define the job states as follows:

```scala mdoc:silent
import scala.concurrent.Future

enum Job[A] {
  case Queued(id: Int, name: String, job: () => A)
  case Running(id: Int, name: String, host: String, result: Future[A])
  case Completed(id: Int, name: String, result: A)
  case Failed(id: Int, name: String, reason: String)
}
```

If you look around the code you work with I expect you'll quickly find many other examples.
