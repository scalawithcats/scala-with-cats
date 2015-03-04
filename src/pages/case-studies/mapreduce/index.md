# Case Study: Pygmy Hadoop

<div class="callout callout-danger">
  TODO: Add content from mapreduce workshop
</div>

<!--
In a previous section we implemented a function `foldMap` that folded a `List` using an implicit `Monoid`. In this project we're going to extend this idea to parallel processing.

If you have used Hadoop or otherwise worked in "big data" you will have heard of [MapReduce][link-mapreduce], which is a programming model for doing parallel data processing across tens or hundreds of machines. As the name suggests, model is built around a *map* phase, which is the same `map` function we know from Scala, and a *reduce* phase, which we usually call `fold`[^hadoop-shuffle].

[^hadoop-shuffle]: In Hadoop there is also a shuffle phase that we will ignore here.

It should be fairly obvious we can apply `map` in parallel. We cannot parallelize `fold` in general, but we can if we restrict the type of reduction functions we allow. What kind of restrictions should be apply? If the function we provide to `fold` is *associative*, we can perform our fold in any order so long as we preserve the ordering on the sequence of elements we're processing. If we have an *identity* element, we can introduce the identity at any point to in our fold and know we won't affect the result.

If this sounds like a monoid, that's because it *is* a monoid. We are not the first to recognise this. The [monoid design pattern for MapReduce jobs][link-mapreduce-monoid] is at the core of recent big data systems such as Twitter's [Summingbird][link-summingbird].

In this project we're going to implement a very simple single-machine MapReduce. In fact, we're just going to parallelize `foldMap` and then look at some of more interesting monoids that are applicable for processing large data sets.

### *FoldMap*

Last time we saw `foldMap` we implemented it as follows:

~~~ scala
implicit class ListFoldable[A](base: List[A]) {
  def foldMap[B : Monoid](f: A => B = (a: A) => a): B =
    base.foldLeft(mzero[B])(_ |+| f(_))
}
~~~

To run the fold in parallel we need to change the implementation strategy. A simple strategy is to allocate as many threads as we have CPUs and evenly partition our sequence amongst the threads. We can simply append the results together as we each thread completes.

Scala provides some simple tools to distribute work amongst threads. We could simply use the [parallel collections library][link-parallel-collections] to implement a solution, but let's dive a bit deeper. You might have already used `Futures`. A `Future` models a computation that may not yet have a value. That is, it represents a value that will become available "in the future". They are a good tool for this sort of job.

### Futures

To execute an operation in parallel we can construct a `Future` as follows:

~~~ scala
import scala.concurrent.Future

val future: Future[String] = Future {
  "construct this string in parallel!"
}
~~~

We need to have an implicit `ExecutionContext` in scope, which determines which thread pool runs the operation. The default `ExecutionContext` is a good choice. We get hold of it with

~~~ scala
import scala.concurrent.ExecutionContext.Implicits.global
~~~

We operate on the value in a `Future` using the familiar `map` and `flatMap` methods. If we have a `Seq[Future[A]]` we can convert it to a `Future[Seq[A]]` using the method `Future.sequence`.

~~~ scala
Future.sequence(Seq(Future(1), Future(2), Future(3)))
// res27: scala.concurrent.Future[Seq[Int]] = // ...
~~~

Finally, we can use `Await.result` to block on a `Future` till a result is available.

~~~ scala
import scala.concurrent.duration.Duration
Await.result(Future(1), Duration.Inf) // Wait forever till a result arrives
~~~

### Partitioning Sequences

We can partition a sequence (actually anything that implements `Iterable`) using the `grouped` method.

~~~ scala
Seq(1, 2, 3, 4).grouped(2)
// res22: Iterator[Seq[Int]] = non-empty iterator

Seq(1, 2, 3, 4).grouped(2).toList
// res23: List[Seq[Int]] = List(List(1, 2), List(3, 4))
~~~


### Parallel FoldMap

Implement a parallel version of `foldMap` called `foldMapP` using the tools described above. Compare performance to the sequential `foldMap`. Here's a method you might find useful for benchmarking:

~~~ scala
def time[A](msg: String)(f: => A): A = {
  // Let Hotspot do some work
  f

  val start = System.nanoTime()
  val result = f
  val end = System.nanoTime()
  println(s"$msg took ${end - start} nanoseconds")
  result
}
~~~

<div class="solution">
The complete model solution can be found in the accompanying code repository in `monoid/src/main/scala/parallel`. The important parts are repeated below.

We found very little difference between parallel and sequential code in terms of performance. This could be an artifact of the benchmarks we used, our hardware, or the overhead of constructing and running parallel code:

~~~ scala
object FoldMap {
  def foldMapP[A, B : Monoid](iter: Iterable[A])(f: A => B = (a: A) => a)(implicit ec: ExecutionContext): B = {
    val nCores: Int = Runtime.getRuntime().availableProcessors()
    val groupSize: Int = (iter.size.toDouble / nCores.toDouble).ceil.round.toInt

    val groups = iter.grouped(groupSize)
    val futures: Iterator[Future[B]] = groups map { group =>
      Future {
        group.foldLeft(mzero[B])(_ |+| f(_))
      }
    }
    val result: Future[B] = Future.sequence(futures) map { iterable =>
      iterable.foldLeft(mzero[B])(_ |+| _)
    }

    Await.result(result, Duration.Inf)
  }

  def foldMap[A, B : Monoid](iter: Iterable[A])(f: A => B = (a: A) => a): B =
    iter.foldLeft(mzero[B])(_ |+| f(_))

  implicit class IterableFoldMapOps[A](iter: Iterable[A]) {
    def foldMapP[B : Monoid](f: A => B = (a: A) => a)(implicit ec: ExecutionContext): B =
      FoldMap.foldMap(iter)(f)

    def foldMap[B : Monoid](f: A => B = (a: A) => a): B =
      FoldMap.foldMap(iter)(f)
  }
}
~~~
</div>

### More Monoids

The monoid instances we have considered so far are very simple. Much more complex and interesting monoids are possible. For example, the [HyperLogLog][link-hyperloglog] algorithm is used to approximate the number of distinct elements in a collection and forms a monoid. It is extremely commonly used in big data applications due to its high accuracy and small storage requirements. Other algorithms for which there is a monoid include the [Bloom filter][link-bloom-filter], a space-efficient probabilistic set, [stochastic gradient descent][link-stochastic-gradient-descent], commonly used to train machine learning models, and the [Top-K algorithm][link-topk], used to find the *K* frequent items in a collection. Scala implementations of all these algorithms can be found in [Algebird][link-algebird].

### Exercise: Folding Without the Hard Work {#folding-without-the-hard-work}

Given a `Monoid[A]` we can easily define a default operation for folding over instances of `List[A]`. Let's call this new method `foldMap` (we'll come to the `map` part in a bit):

~~~ scala
List(1, 2, 3).foldMap
// res0: List[Int] = 6
~~~

Implement `foldMap` now. Use an `implicit class` to add the method to `List[A]` for any `A`. The method should automatically select an appropriate `Monoid[A]` using implicits:

<div class="solution">
There are two possible solutions to this. Each involves defining an `implicit class` to wrap `List[A]` and provide the `foldMap` method. We'll call this implicit class `FoldMapOps`.

The first solution puts a context bound on the type parameter for `FoldMapOps`. This restricts the compiler so it can only materialize a `FoldMapOps[A]` if there is a `Monoid[A]` in scope:

~~~ scala
implicit class FoldMapOps[A: Monoid](base: List[A]) {
  def foldMap: A =
    base.foldLeft(mzero[A])(_ |+| _)
}
~~~

The second solution moves the implicit parameter to the `foldMap` method. This allows the compiler to materialize `FoldMapOps` for any `A`, but prevents us calling `foldMap` unless there is a `Monoid` in scope.

~~~ scala
implicit class FoldMapOps[A](base: List[A]) {
  def foldMap(implicit monoid: Monoid[A]): A =
    base.foldLeft(mzero[A])(_ |+| _)
}
~~~

Either of these approaches works just fine, but the second implementation is mildly preferable because of the error messages it generates when there is no matching `Monoid` in scope. Putting the context bound on the constructor gives us the following:

~~~ scala
List('a, 'b, 'c).foldMap
// <console>:16: error: value foldMap is not a member of List[Symbol]
//               List('a, 'b, 'c).foldMap
//                                ^
~~~

whereas putting the parameter on `foldMap` gives us a much more precise error message:

~~~ scala
List('a, 'b, 'c).foldMap
// <console>:16: error: could not find implicit value ↩
//    for parameter monoid: scalaz.Monoid[Symbol]
//               List('a, 'b, 'c).foldMap
//                                ^
~~~
</div>

Now let's implement the `map` part of `foldMap`. Extend `foldMap` so it takes a function of type `A => B`, where there is a monoid for `B`, and returns a result of type `B`. If no function is specified it should default to the identity function `a => a`. Here's an example:

~~~ scala
List(1, 2, 3).foldMap[Int]()
// res0: Int = 6

List("1", "2", "3").foldMap[Int](_.toInt)
// res1: Int = 6
~~~

Note: we no longer need a monoid for `A`.

<div class="solution">
~~~ scala
implicit class FoldMapOps[A](base: List[A]) {
  def foldMap[B : Monoid](f: A => B = (a: A) => a): B =
    base.foldLeft(mzero[B])(_ |+| f(_))
}
~~~
</div>

It won't come as a surprise to learn we aren't the first to make this connection between fold and monoids. Scalaz provides an abstraction called [`Foldable`][scalaz.Foldable] that implements `foldMap`. We can use it by importing `scalaz.syntax.foldable._`:

~~~ scala
import scalaz.std.anyVal._
import scalaz.std.list._
import scalaz.syntax.foldable._

List(1, 2, 3).foldMap()
// res2: Int = 6

List(1, 2, 3).foldMap(_.toString)
// res3: String = "123"
~~~

Scalaz provides a number of instances for `Foldable`:

~~~ scala
import scalaz.std.iterable._
import scalaz.std.tuple._
import scalaz.std.string._

Map("a" -> 1, "b" -> 2).foldMap()
// res4: (String, Int) = (ab, 3)

Set(1, 2, 3).foldMap(_.toString)
// res5: String = "123"
~~~

### Exercise: Monadic FoldMap

It's useful to allow the user of `foldMap` to perform monadic actions within their mapping function. This, for example, allows the mapping to indicate failure by returning an `Option`.

Implement a variant of `foldMap` called `foldMapM` that allows this. The focus here is on the monadic component, so you can base your code on `foldMap` or `foldMapP` as you see fit. Here are some examples of use:

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
The full solution is implemented in `monad/src/main/scala/parallel/FoldMap.scala`. Here's the most important part:

~~~ scala
def foldMapM[A, M[_] : Monad, B: Monoid](iter: Iterable[A])(f: A => M[B]): M[B] =
  iter.foldLeft(mzero[B].point[M]){ (accum, elt) =>
    for {
      a <- accum
      b <- f(elt)
    } yield a |+| b
  }
~~~
</div>

### A Higher Kind of FoldMap

When we looked at `foldMap` earlier, we couldn't write a type class for it because we didn't know how to write the type of the objects that type class should work over. Now we know about higher kinds, we can revisit this problem.

Define all the machinery needed for a `FoldMappable` type class: the trait, an interface, some instances, and an enrichment.

<div class="solution">
This exercise is really intended to make us practive defining and using higher kinds. Here is the model solution:

~~~ scala
import scala.language.higherKinds
import scalaz.Monoid
import scalaz.syntax.monoid._

trait FoldMappable[F[_]] {
  def foldMap[A, B : Monoid](fa: F[A])(f: A => B): B
}

object FoldMappable {
  def apply[F[_] : FoldMappable]: FoldMappable[F] =
    implicitly[FoldMappable[F]]

  implicit object ListFoldMappable extends FoldMappable[List] {
    def foldMap[A, B : Monoid](fa: List[A])(f: A => B): B =
      fa.foldLeft(mzero[B]){ _ |+| f(_) }
  }
}

object FoldMappableSyntax {
  implicit class IsFoldMappable[F[_] : FoldMappable, A](fa: F[A]) {
    def foldMap[B : Monoid](f: A => B): B =
      FoldMappable[F].foldMap(fa)(f)
  }
}
~~~
</div>
-->