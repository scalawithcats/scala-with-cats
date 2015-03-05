# Case Study: Pygmy Hadoop

In this case study we're going to implement a simple-but-powerful parallel processing framework using `Monoids`, `Functors`, and a host of other goodies.

If you have used Hadoop or otherwise worked in "big data" you will have heard of [MapReduce][link-mapreduce], which is a programming model for doing parallel data processing across tens or hundreds of machines. As the name suggests, model is built around a *map* phase, which is the same `map` function we know from Scala and the `Functor` type class, and a *reduce* phase, which we usually call `fold`[^hadoop-shuffle].

[^hadoop-shuffle]: In Hadoop there is also a shuffle phase that we will ignore here.

## Parallelizing *map* and *fold*

It should be obvious that we can apply `map` in parallel. We can't parallelize `fold` in general, but we can if we restrict the type of reduction functions we allow.

What kind of restrictions should be apply to `fold`? If the iterator function is *associative*, we can perform our fold in any order so long as we preserve the ordering on the sequence of elements we're processing. If we have an *identity* element, we can introduce the identity at any point to in our fold and know we won't affect the result.

If this sounds like a monoid, that's because it *is* a monoid. We are not the first to recognise this. The [monoid design pattern for MapReduce jobs][link-mapreduce-monoid] is at the core of recent big data systems such as Twitter's [Summingbird][link-summingbird].

In this project we're going to implement a very simple single-machine MapReduce. We'll start by implementing a method called `foldMap` to model the data-flow we need. We'll then parallelize `foldMap` and then look at some of more interesting monoids that are applicable for processing large data sets.

## Implementing *FoldMap*

Let's implement a method `foldMap` that:

 - accepts a sequence parameter of type `Iterable[A]` and a function of type `A => B`;
 - maps the function over the sequence;
 - reduces the results using the monoid for `A`.

Here's a basic type signature. You will have to add implicit parameters or context bounds to complete the type signature:

~~~ scala
def foldMap[A, B](values: Iterable[A])(func: A => B): B =
  ???
~~~

Here's some sample output:

~~~ scala
// Missing the second argument supplies the identity function.
// The monoid in use here is integer addition:
foldMap(List(1, 2, 3))()
// res0: Int = 6

// Mapping to a String uses the concatenation monoid:
foldMap(Seq(1, 2, 3))(_.toString + "! ")
// res1: String = 1! 2! 3!

// Mapping over a String to produce a String:
foldMap("Hello world!")(_.toString.toUpperCase)
// res2: String = "HELLO WORLD!"
~~~

<div class="solution">
We have to modify the type signature to accept a `Monoid` for `B`. With that change we can use the `mzero` and `|+|` syntax [described in the monoids chapter](#monoid-syntax):

~~~ scala
import scalaz.Monoid
import scalaz.std.anyVal._
import scalaz.std.string._
import scalaz.syntax.monoid._

def foldMap[A, B : Monoid](values: Iterable[A])(func: A => B = (a: A) => a): B =
  values.map(func).foldLeft(mzero[B])(_ |+| _)
~~~

We can make a slight alteration to this code to do everything in one step:

~~~ scala
def foldMap[A, B : Monoid](values: Iterable[A])(func: A => B = (a: A) => a): B =
  values.foldLeft(mzero[B])(_ |+| func(_))
~~~
</div>

## Parallelising *foldMap*

To run the fold in parallel we need to change our implementation strategy. A simple strategy is to allocate as many threads as we have CPUs and evenly partition our sequence amongst the threads. We can append the results together as we each thread completes.

Scala provides some simple tools to distribute work amongst threads. We could simply use the [parallel collections library][link-parallel-collections] to implement a solution, but let's challenge ourselves by diving a bit deeper. You might have already used `Futures`. A `Future` models a computation that may not yet have a value. That is, it represents a value that will become available "in the future". They are a good tool for this sort of job.

Before we begin we need to introduce some new building blocks: *futures* and *partioning sequences*.

### Futures

To execute an operation in parallel we can construct a `Future` as follows:

~~~ scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

val future: Future[String] = Future {
  "Construct this string in parallel!"
}
// future: Future[String] = ...
~~~

We need to have an implicit `ExecutionContext` in scope, which determines which thread pool runs the operation. The default `ExecutionContext.Implicits.global` shown above is a good choice, but we can use any choice in practice.

We operate on the value in a `Future` using the familiar `map` and `flatMap` methods:

~~~ scala
val future2 = future.map(_.length)
// future2: Future[Int] = ...

val future3 = future.flatMap { length =>
  Future { length * 1000 }
}
// future3: Future[Int] = ...
~~~

If we have a `Seq[Future[A]]` we can convert it to a `Future[Seq[A]]` using the method `Future.sequence`:

~~~ scala
Future.sequence(Seq(Future(1), Future(2), Future(3)))
// res3: scala.concurrent.Future[Seq[Int]] = // ...
~~~

Finally, we can use `Await.result` to block on a `Future` till a result is available.

~~~ scala
import scala.concurrent.duration.Duration

Await.result(Future(1), Duration.Inf) // wait forever until a result arrives
~~~

There are even `Monad` and `Monoid` implementations for `Future`. We have to be careful to refer to Scala `Futures` here because Scalaz has its own `Future` implementation with conflicting names:

~~~ scala
import scalaz.std.scalaFuture._
~~~

### Partitioning Sequences

We can partition a sequence (actually anything that implements `Iterable`) using the `grouped` method. We'll use this to split off chunks of work for each CPU:

~~~ scala
Seq(1, 2, 3, 4).grouped(2)
// res4: Iterator[Seq[Int]] = non-empty iterator

Seq(1, 2, 3, 4).grouped(2).toList
// res5: List[Seq[Int]] = List(List(1, 2), List(3, 4))
~~~

We can query the number of available CPUs on our machine using this API call to the Java standard library:

~~~ scala
Runtime.getRuntime.availableProcessors
// res6: Int = 8
~~~

### Parallel FoldMap

Implement a parallel version of `foldMap` called `foldMapP` using the tools described above:

~~~ scala
def foldMapP[A, B : Monoid]
    (values: Iterable[A])
    (func: A => B = (a: A) => a)
    (implicit ec: ExecutionContext): Future[B] = ???
~~~

Start by splitting the input into a set of even chunks, one per CPU. Create a future to do the work for each chunk using `foldMap`, and then `foldMap` cross the futures.

<div class="solution">
The annotated solution is below:

~~~ scala
import scala.concurrent.{Await, Future, ExecutionContext}
import scala.concurrent.duration.Duration
import scala.concurrent.ExecutionContext.Implicits.global

def foldMapP[A, B : Monoid]
    (values: Iterable[A])
    (func: A => B = (a: A) => a)
    (implicit ec: ExecutionContext): Future[B] = {
  // Calculate the number of items to pass to each CPU:
  val numCores: Int = Runtime.getRuntime.availableProcessors
  val groupSize: Int = (1.0 * values.size / numCores).ceil.toInt

  // Create one group for each CPU:
  val groups: Iterator[Iterable[A]] =
    values.grouped(groupSize)

  // Create a future to foldMap each group:
  val futures: Iterator[Future[B]] =
    groups map { group =>
      Future {
        group.foldLeft(mzero[B])(_ |+| func(_))
      }
    }

  // foldMap over the groups to calculate a final result:
  Future.sequence(futures) map { iterable =>
    iterable.foldLeft(mzero[B])(_ |+| _)
  }
}

Await.result(foldMapP(1 to 1000000)(), Duration.Inf)
// res12: Int = 1784293664
~~~
</div>

### Monadic *foldMap*

It's useful to allow the user of `foldMap` to perform monadic actions within their mapping function. This, for example, allows the mapping to indicate failure by returning an `Option`.

Implement a variant of `foldMap` called `foldMapM` that allows this. Here's the basic type signature---add implicit parameters and context bounds as necessary to make your code compile:

~~~ scala
def foldMapM[A, M[_], B](iter: Iterable[A])(f: A => M[B]): M[B] =
  ???
~~~

The focus here is on the monadic component so base your code on `foldMap` for simplicity. Here are some examples of use:

~~~ scala
import scalaz.std.anyVal._
import scalaz.std.option._
import scalaz.std.list._

val seq = Seq(1, 2, 3)

seq.foldMapM(a => some(a))
// res4: Option[Int] = Some(6)

seq.foldMapM(a => List(a))
// res5: List[Int] = List(6)

seq.foldMap(a => if(a % 2 == 0) some(a) else none[Int])
// res6: Option[Int] = Some(2)
~~~

<div class="solution">
First we change the type of our `func` parameter from `A => B` to `A => M[B]` and bring in the `Monoid` for `M`. Then we tweak the method implementation to `flatMap` over the monad and call `|+|`:

~~~ scala
def foldMapM[A, M[_]: Monad, B: Monoid](iter: Iterable[A])(f: A => M[B]): M[B] =
  iter.foldLeft(mzero[B].point[M]) { (accum, elt) =>
    for {
      a <- accum
      b <- f(elt)
    } yield a |+| b
  }
~~~
</div>

### Exercise: Everything is Monadic

We can unify monadic and normal code by using the `Id` monad described in the [Monads chapter](#id-monad). Using this trick, implement a default `func` parameter for `foldMapM`. This allows us to write code like:

~~~ scala
seq.foldMapM()
// res10: scalaz.Id.Id[Int] = 6
~~~

<div class="solution">
We have `Monad[B]` in scope in our method header, so all we need to do is use the `point` syntax:

~~~ scala
imporgt scalaz.syntax.monad._

def foldMapM[A, M[_] : Monad, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
  iter.foldLeft(mzero[B].point[M]) { (accum, elt) =>
    for {
      a <- accum
      b <- f(elt)
    } yield a |+| b
  }
~~~
</div>

It also allows us to implement `foldMap` in terms of `foldMapM`. Try it!

<div class="solution">
~~~ scala
def foldMap[A, B : Monoid](iter: Iterable[A])(f: A => B = (a: A) => a): B =
  foldMapM[A, Id, B](iter) { a => f(a).point[Id] }
~~~
</div>

### Exercise: Seeing is Believing

Call `foldMapM` using the `\/` monad and verify that it really does stop execution as soon an error is encountered.  Start by writing a type alias to convert `\/` to a type constructor with one parameter. We'll use the `str.parseInt.disjunction` syntax to read input, so define your alias using an appropriate error type:

~~~ scala
import scalaz.syntax.std.string._

"Cat".parseInt.disjunction
// res8: scalaz.\/[NumberFormatException,Int] = ↩
//   -\/(java.lang.NumberFormatException: For input string: "Cat")

"1".parseInt.disjunction
// res9: scalaz.\/[NumberFormatException,Int] = \/-(1)
~~~

Once you have your type alias, call `foldMapM`. Start with a sequence of `Strings`---both valid and invalid input---and see what results you get:

<div class="solution">
The `"123".parseInt.disunction` approach gives us a `NumberFormatException \/ Int` so we'll go with `NumberFormatException` as our error type:

~~~ scala
type ParseResult[A] = NumberFormatException \/ A
~~~

Now we can use `foldMapM`. The resulting code iterates over the sequence, adding up numbers using the `Monoid` for `Int` until a `NumberFormatException` is encountered. At that point the `Monad` for `\/` fails fast, returning the failure without processing the rest of the list:

~~~ scala
foldMapM[String, ParseResult, Int](Seq("1", "2", "3"))(_.parseInt.disjunction)
// res0: ParseResult[Int] = \/-(6)

foldMapM[String, ParseResult, Int](Seq("1", "x", "3"))(_.parseInt.disjunction)
// res1: ParseResult[Int] = -\/(java.lang.NumberFormatException: For input string: "x")
~~~
</div>
