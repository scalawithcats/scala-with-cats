## Applications of Algebraic Data Types

We seem some examples of algebraic data types already. Some of the simplest are the basic enumeration, like

```scala mdoc:silent
enum Permissions {
  case User
  case Moderator
  case Admin
}
```

which we might use in a system monitoring application and also our old friend the `case class`

```scala mdoc:silent
final case class Uri(protocol: String, host: String, port: Int, path: String)
```

I think these are the straightforward examples, but those new to algebraic data types often don't realise how many other uses cases there are.
We'll see combinator libraries, an extremely important use, in the next chapter.
Here I want to give a few examples of finite state machines as another use case.

Finite state machines occur everywhere in programming. The state of a user interface component, such as open or closed, or visible or invisible, can be modelled as a finite state machine. The state of a job in a distributed job system, like Spark, can also be modelled as a finite state machine. 
When using an algebraic data type we're not restricted to simple enumerations of state.
We can also store data within the states.
So, in our job control system, we define jobs as having states.
Here's a simple example.

```scala mdoc:silent
import scala.concurrent.Future

enum Job[A] {
  case Queued(name: String, job: () => A)
  case Running(name: String, host: String, result: Future[A])
  case Completed(name: String, result: A)
  case Failed(name: String, reason: String)
}
```
