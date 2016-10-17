## *Traverse*

`foldLeft` and `foldRight` are flexible iteration methods
but they require us to do a lot of work 
to define accumulators and combinator functions.
The `Traverse` type class is a higher level tool 
that leverages `Applicatives` to provide 
a more convenient, more lawful, pattern for iteration.
For those who are interested, `Traverse` comes from 
[this 2006 paper][link-gibbons-oliviera-iterator-pattern] 
by Jeremy Gibbons and Bruno Oliviera.

### Traversing with Futures

We can demonstrate `Traverse` using
the `Future.traverse` and `Future.sequence` methods in the Scala standard library.
These methods provide `Future`-specific implementations of the traverse pattern.
As an example, suppose we have a list of server hostnames
and a method to poll a host for its uptime:

```tut:book:silent
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

val hostnames = List("alpha.example.com", "beta.example.com", "gamma.demo.com")

def getUptime(hostname: String): Future[Int] =
  Future(hostname.length * 60) // just for demonstration
```

Now, suppose we want to poll all of the hosts and collect all of their uptimes.
We can't simply `map` over `hostnames`
because the result---a `List[Future[Int]]`---would contain more than one `Future`.
To get something we can block on, we need to reduce the results to a single `Future`.
Let's start by doing this manually using a fold:

```tut:book:silent
val allUptimes: Future[List[Int]] =
  hostnames.foldLeft(Future(List[Int]())) { (uptimes, host) =>
    val uptime = getUptime(host)
    for {
      uptimes <- uptimes
      uptime  <- uptime
    } yield uptimes :+ uptime
  }
```

```tut:book
Await.result(allUptimes, Duration.Inf)
```

Intuitively, we iterate over `hostnames`, call `func` for each item,
and combine the results into a list.
This sounds simple, but the code is fairly unwieldy
because of the need to create and combine `Futures` at every iteration.
We can improve on things greatly using `Future.traverse`,
which is tailor made for this pattern:

```tut:book:silent
val allUptimes: Future[List[Int]] =
  Future.traverse(hostnames)(getUptime)
```

```tut:book
Await.result(allUptimes, Duration.Inf)
```

This is much clearer and more concise---let's see how it works.
If we ignore distractions like `CanBuildFrom` and `ExecutionContext`,
the implementation of `Future.traverse` in the standard library looks like this:

```scala
object Future {
  def traverse[A, B](futures: List[A])(func: A => Future[B]): Future[List[B]] =
    hostnames.foldLeft(Future(List[A]())) { (accum, host) =>
      val item = func(host)
      for {
        accum <- accum
        item  <- item
      } yield accum :+ item
    }
}
```

This is essentially the same as our example code above.
`Future.traverse` takes away the pain of folding
and defining accumulators and combination functions,
and gives us a clean high-level interface to do what we want:

- start with a `List[A]`;
- provide a function `A => Future[B]`;
- end up with a `Future[List[B]]`.

The standard library also provides another method, `Future.sequence`,
that assumes we're starting with a `List[Future[B]]`
and don't need to provide an identity function:

```scala
object Future {
  def sequence[B](futures: List[Future[B]]): Future[List[B]] =
    traverse(futures)(identity)

  // etc...
}
```

In this case the intuitive understanding is even simpler:

- start with a `List[Future[A]]`;
- end up with a `Future[List[A]]`.

`Future.traverse` and `Future.sequence` 
solve a very specific problem:
they allow us to iterate over a sequence of `Futures`
and accumulate a result.
The simplified examples above only work with `Lists`,
but the real `Future.traverse` and `Future.sequence`
work with any standard Scala collection.

Cats' `Traverse` type class generalises the `traverse` and `sequence` patterns
to work with any type of "effect",
including `Future`, `Option`, `Validated`, and so on.
We'll approach `Traverse` in the next sections in two steps:
first we'll generalise over the effect type,
then we'll generalise over the sequence type.
We'll end up with an extremely valuable tool that trivialises
many operations involving sequences and other data types.

### Traversing with Applicatives

If we squint, we'll see that we can rewrite the `traverse` method in terms of an `Applicative`.
Our accumulator, which was the following for `Future`:

```tut:book:silent
val oldAccum = Future(List[Int]())
```

is equivalent to `Applicative.pure`:

```tut:book:silent
import cats.Applicative
import cats.instances.future._
import cats.syntax.applicative._

val newAccum = List[Int]().pure[Future]
```

Our combinator, which used to be this:

```tut:book:silent
def oldCombine(uptimes: Future[List[Int]], host: String): Future[List[Int]] = {
  val uptime = getUptime(host)
  for {
    uptimes <- uptimes
    uptime  <- uptime
  } yield uptimes :+ uptime
}
```

is now equivalent to `Cartesian.combine`:

```tut:book:silent
import cats.syntax.cartesian._

// Combining an accumulator and a hostname using an Applicative:
def newCombine(accum: Future[List[Int]], host: String): Future[List[Int]] =
  (accum |@| getUptime(host)).map(_ :+ _)
```

If we substitute these snippets back into the definition of `traverse`,
we can generalise it to to work with any `Applicative`:

```tut:book:silent
import scala.language.higherKinds

def listTraverse[F[_] : Applicative, A, B](inputs: List[A])(func: A => F[B]): F[List[B]] =
  inputs.foldLeft(List.empty[B].pure[F]) { (accum, item) =>
    (accum |@| func(item)).map(_ :+ _)
  }

def listSequence[F[_] : Applicative, B](inputs: List[F[B]]): F[List[B]] =
  listTraverse(inputs)(identity)
```

We can use this new `listTraverse` to re-implement our uptime example:

```tut:book
Await.result(listTraverse(hostnames)(getUptime), Duration.Inf)
```

or we can use it with with other `Applicative` data types
as shown in the following exercises.

#### Exercise: Traversing with Vectors

What is the result of the following?

```tut:book:silent
import cats.instances.vector._

listSequence(List(Vector(1, 2), Vector(3, 4)))
```

<div class="solution">
The argument is of type `List[Vector[Int]]`,
so we're using the `Applicative` for `Vector`
and the return type is going to be `Vector[List[Int]]`.

`Vector` is a monad,
so its cartesian `combine` function is based on `flatMap`.
We'll end up with a `Vector` of `Lists`
of all the possible combinations of `List(1, 2)` and `List(3, 4)`:

```tut:book
listSequence(List(Vector(1, 2), Vector(3, 4)))
```
</div>

What about a list of three parameters?

```tut:book:silent
listSequence(List(Vector(1, 2), Vector(3, 4), Vector(5, 6)))
```

<div class="solution">
With three items in the input list, we end up with combinations of three `Ints`:
one from the first item, one from the second, and one from the third:

```tut:book
listSequence(List(Vector(1, 2), Vector(3, 4), Vector(5, 6)))
```
</div>

#### Exercise: Traversing with Options

Here's an example that uses `Options`:

```tut:book:silent
import cats.instances.option._

def process(inputs: List[Int]) =
  listTraverse(inputs)(n => if(n % 2 == 0) Some(n) else None)
```

What is the return type of this method? What does it produce for the following inputs?

```tut:book:silent
process(List(2, 4, 6))
process(List(1, 2, 3))
```

<div class="solution">
The arguments to `listTraverse` are of types `List[Int]` and `Int => Option[Int]`,
so the return type is `Option[List[Int]]`.
Again, `Option` is a monad,
so the cartesian `combine` function follows from `flatMap`.
The semantics are therefore fail fast error handling:
if all inputs are even, we get a list of outputs.
Otherwise we get `None`:

```tut:book
process(List(2, 4, 6))
process(List(1, 2, 3))
```
</div>

#### Exercise: Traversing with Validated

Finally, gere's an example that uses `Validated`:

```tut:book:silent
import cats.data.Validated
import cats.instances.list._ // Applicative[ErrorOr] needs a Monoid[List]

type ErrorOr[A] = Validated[List[String], A]

def process(inputs: List[Int]): ErrorOr[List[Int]] =
  listTraverse(inputs) { n =>
    if(n % 2 == 0) {
      Validated.valid(n)
    } else {
      Validated.invalid(List(s"$n is not even"))
    }
  }
```

What does this method produce for the following inputs?

```tut:book:silent
process(List(2, 4, 6))
process(List(1, 2, 3))
```

<div class="solution">
The return type here is `ErrorOr[List[Int]]`,
which expands to `Validated[List[String], List[Int]]`.
The semantics for cartesian `combine` on validated are accumulating error handling,
so the result is either a list of even `Ints`,
or a list of errors detailing which `Ints` failed the test:

```tut:book
process(List(2, 4, 6))
process(List(1, 2, 3))
```
</div>
