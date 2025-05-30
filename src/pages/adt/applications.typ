#import "../stdlib.typ": info, warning, solution
== Finite State Machines as Algebraic Data Types


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

+ Queued: the job is in the queue to be run.
+ Running: the job is running on a computer.
+ Completed: the job successfully finished and we have collected the result.
+ Failed: the job failed to run to completion.

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

It's often the case that we want to define methods on only a subset of the states in a finite state machine. A simple example is a resource, like a file, that can be either open or closed. An open file can be closed and a closed file can be opened, but not vice versa. There are a number of ways to model this, and we don't yet have all the tools to see all the possible implementations. However one particularly simple implementation is to use the not-quite algebraic data type approach hinted at in an earlier section.

```scala mdoc:silent
sealed abstract class Resource

final case class Open() extends Resource {
  def close: Closed = ???
}
final case class Closed() extends Resource {
  def open: Open = ???
}
```

In this approach we need to be careful with types of methods that are common across states.
For example, image we have a method `copy` to duplicate a `Resource`.
We could define this as

```scala
sealed abstract class Resource {
  def copy: Resource
}
```

but this loses the type information of whether a `Resource` is open or closed, and therefore we cannot call the `open` or `close` method on a copy without an unsafe cast.

Another approach is to simply duplicate the `copy` method with the appropriate return type.

```scala mdoc:reset:silent
sealed abstract class Resource

final case class Open() extends Resource {
  def copy: Open = ???
  def close: Closed = ???
}
final case class Closed() extends Resource {
  def copy: Closed = ???
  def open: Open = ???
}
```

This solves the problem but introduces its own limitations: it can require a lot of code duplication, and there is no way to write a method that copies either an `Open` or `Closed` resource. One way to address these is with what is called *F-bound polymorphism*.

```scala mdoc:reset:silent
sealed abstract class Resource[Self <: Resource[Self]] {
  def copy: Self = ???
}

final case class Open() extends Resource[Open] {
  def close: Closed = ???
}
final case class Closed() extends Resource[Closed] {
  type Self = Closed

  def open: Open = ???
}
```

The solution we should take depends on the context. F-bound polymorphism is confusing to many new programmers, and the simpler solution we saw earlier may work depending on our requirements. Later on we'll address this problem with using parameters, known as implicit parameters in Scala 2.
