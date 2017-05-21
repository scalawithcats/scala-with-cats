# Case Study: Testing Asynchronous Code

We'll start with a simple case study:
how to simplify unit tests for asynchronous code
by making them synchronous.

Let's return to the example
from Chapter [@sec:foldable-traverse]
where we're measuring the uptime on a set of servers.
We have two components to our code.
The first is an `UptimeClient`
that polls remote servers for their uptime:

```tut:book:silent
import scala.concurrent.Future

trait UptimeClient {
  def getUptime(hostname: String): Future[Int]
}
```

We'll also have an `UptimeService` that maintains a list of servers
and allows the user to poll them for their total uptime:

```tut:book:silent
import cats.instances.future._
import cats.instances.list._
import cats.syntax.traverse._
import scala.concurrent.ExecutionContext.Implicits.global

class UptimeService(client: UptimeClient) {
  def getTotalUptime(hostnames: List[String]): Future[Int] =
    hostnames.traverse(client.getUptime).map(_.sum)
}
```

We've modelled `UptimeClient` as a trait
because we're going to want to stub it out in unit tests.
For example, we can write a test client
that allows us to provide test data:

```tut:book:silent
class TestUptimeClient(hosts: Map[String, Int]) extends UptimeClient {
  def getUptime(hostname: String): Future[Int] =
    Future.successful(hosts.getOrElse(hostname, 0))
}
```

Now let's suppose we're writing unit tests for `UptimeService`.
We want to test its ability to sum uptimes
using the `TestUptimeClient` to provide the raw data.
Here's an example using `assert`:

```tut:book:fail
def testTotalUptime() = {
  val hosts    = Map("host1" -> 10, "host2" -> 6)
  val client   = new TestUptimeClient(hosts)
  val service  = new UptimeService(client)
  val actual   = service.getTotalUptime(hosts.keys.toList)
  val expected = hosts.values.sum
  assert(actual == expected)
}
```

The code doesn't compile
because we've made a classic error[^warnings].
We forgot that our application code is asynchronous.
Our `actual` result is of type `Future[Int]`
and out `expected` result is of type `Int`.
We can't compare them directly!

[^warnings]: Technically this is a *compiler warning* not an error.
It has been promoted to an error in our case
because we're using the `-Xfatal-warnings` flag on `scalac`.
We recommend using this flag to avoid gotchas like this!

There are numerous ways to solve this problem.
We could block on the future and make the test synchronous.
Or we could rewrite the whole test to be asynchronous,
blocking on the final result.
However, there is another alternative:
to make our service code synchronous
so the test above works without modification!

## Abstracting over Type Constructors

We need to implement two versions of `UptimeClient`:
an asynchronous one for use in production
and a synchronous one for use in our unit tests:

```scala
trait RealUptimeClient extends UptimeClient {
  def getUptime(hostname: String): Future[Int]
}

trait TestUptimeClient extends UptimeClient {
  def getUptime(hostname: String): Int
}
```

To do this we need to abstract over
the two return types for `getUptime`:
`Future[Int]` and `Int`:

```scala
trait UptimeClient {
  def getUptime(hostname: String): ???
}
```

At first this may seem like a difficult task.
We want to retain the `Int` part from each type
but "throw away" the `Future` part when we're writing tests.
Fortunately, we can make the problem much simpler
using the the *identity monad*
that we discussed way back in Section [@sec:id-monad].
If you remember, Cats provides a type alias
that allows us to "wrap" simple types in a type constructor
without changing their meaning:

```scala
package cats

type Id[A] = A
```

We can use `Id` to convert the return types
for `getUptime` to the same shape.
This allows us to abstract over them in `UptimeClient`.
Do this now:

- write a trait definition for `UptimeClient`
  that accepts a type constructor `F[_]` as a parameter;

- extend it with two traits,
  `RealUptimeClient` and `TestUptimeClient`,
  that bind `F` to `Future` and `Id` respectively;

- write out the method header for `getUptime`
  in each case to verify that it compiles.

<div class="solution">
Here's the basic implementation:

```tut:book:silent
import scala.language.higherKinds
import cats.Id

trait UptimeClient[F[_]] {
  def getUptime(hostname: String): F[Int]
}

trait RealUptimeClient extends UptimeClient[Future] {
  def getUptime(hostname: String): Future[Int]
}

trait TestUptimeClient extends UptimeClient[Id] {
  def getUptime(hostname: String): Id[Int]
}
```

Note that, because `Id[A]` is just a simple alias for `A`,
we don't even need to refer to the return type in `TestUptimeClient`
as `Id[Int]`---we can simply write `Int` instead:

```tut:book:silent
trait TestUptimeClient extends UptimeClient[Id] {
  def getUptime(hostname: String): Int
}
```
</div>

You should now be able to flesh your definition of `TestUptimeClient`
out into a full class based on a `Map[String, Int]` as before.

<div class="solution">
Now we're not dealing with `Futures`,
the code is even simpler than before:

```tut:book:silent
object wrapper {
  class TestUptimeClient(hosts: Map[String, Int])
    extends UptimeClient[Id] {
    def getUptime(hostname: String): Int =
      hosts.getOrElse(hostname, 0)
  }
}; import wrapper._
```
</div>

## Abstracting over Monads

Let's turn our attention to `UptimeService`.
We need to rewrite it to abstract over
the two types of `UptimeClient`.
We'll do this in two stages:
we'll get the class and method headers compiling first,
then we'll turn our attention to the method bodies.
Starting with the method headers:

- comment out the body of `getTotalUptime`
  (replace it with `???` to make everything compile);

- add a type parameter `F[_]` to `UptimeService`
  and pass it on to `UptimeClient`.

<div class="solution">
The code should look like this:

```tut:book:silent
class UptimeService[F[_]](client: UptimeClient[F]) {
  def getTotalUptime(hostnames: List[String]): F[Int] =
    ???
    // hostnames.traverse(client.getUptime).map(_.sum)
}
```
</div>

Now uncomment the body of `getTotalUptime`.
You should get a compilation error similar to the following:

```scala
// <console>:28: error: could not find implicit value for
//               evidence parameter of type cats.Applicative[F]
//            hostnames.traverse(client.getUptime).map(_.sum)
//                              ^
```

The problem here is that the `traverse` method only works
on sequences of values that have an `Applicative`.
In our original code we were traversing a `List[Future[Int]]`
and there is an applicative for `Future`.
In this code we are traversing a `List[F[Int]]`.
We need to *prove* to the compiler that `F` has an `Applicative`.
Do this by adding an implicit constructor parameter
to `UptimeService`.

<div class="solution">
We can write this as a full implicit parameter:

```tut:book:silent
import cats.Applicative
import cats.syntax.functor._
```

```tut:book:silent
object wrapper {
  class UptimeService[F[_]](client: UptimeClient[F])
      (implicit a: Applicative[F]) {

    def getTotalUptime(hostnames: List[String]): F[Int] =
      hostnames.traverse(client.getUptime).map(_.sum)
  }
}; import wrapper._
```

or more tersely as a context bound:

```tut:book:silent
object wrapper {
  class UptimeService[F[_]: Applicative]
      (client: UptimeClient[F]) {

    def getTotalUptime(hostnames: List[String]): F[Int] =
      hostnames.traverse(client.getUptime).map(_.sum)
  }
}; import wrapper._
```

Note that we need to import `cats.syntax.functor`
as well as `cats.Applicative`.
This is because we're switching from using
the `map` of `Future` to Cats' extension method
that requires an implicit `Functor` as a parameter.
</div>


Finally, let's turn our attention to our unit tests.
Our test code now works exactly as intended.
We create an instance of `TestUptimeClient`
and wrap it in an `UptimeService`.
This effectively binds `F` to `Id`,
allowing the rest of the code to operate
synchronously without worrying about monads or applicatives:

```tut:book:invisible:reset
import cats.Id
import cats.Applicative
import cats.instances.list._
import cats.syntax.functor._
import cats.syntax.traverse._
import scala.concurrent.Future
import scala.language.higherKinds

object wrapper {
  trait UptimeClient[F[_]] {
    def getUptime(hostname: String): F[Int]
  }

  trait RealUptimeClient extends UptimeClient[Future]

  class TestUptimeClient(hosts: Map[String, Int])
      extends UptimeClient[Id] {
    def getUptime(hostname: String): Int =
      hosts.getOrElse(hostname, 0)
    }

  class UptimeService[F[_]: Applicative]
      (client: UptimeClient[F]) {

    def getTotalUptime(hostnames: List[String]): F[Int] =
      hostnames.traverse(client.getUptime).map(_.sum)
  }
}; import wrapper._
```

```tut:book:silent
def testTotalUptime() = {
  val hosts    = Map("host1" -> 10, "host2" -> 6)
  val client   = new TestUptimeClient(hosts)
  val service  = new UptimeService(client)
  val actual   = service.getTotalUptime(hosts.keys.toList)
  val expected = hosts.values.sum
  assert(actual == expected)
}

testTotalUptime()
```

## Conclusions

This case study provides a nice
introduction to how Cats can help us
abstract over different computational scenarios.
We used the `Applicative` type class
to abstract over asynchronous and synchronous
scenarios for collecting values (uptime measurements)
from a set of data sources (servers and fake servers).

Back in Figure [@fig:applicatives:hierarchy],
we outlined a "stack" of computational type classes
that are useful for just this kind of abstraction.
We used `Applicative` here because it was
the least powerful type class that did what we needed.
If we had required `flatMap`,
we could have swapped out `Applicative` for `Monad`.
There are also type classes like `ApplicativeError`
and `MonadError` that help model failures
as well as successful computations.

Let's move on now to a more complex case study
where we'll look at the application of type classes
to a more concrete scenario:
a map-reduce-style framework for parallel processing.
