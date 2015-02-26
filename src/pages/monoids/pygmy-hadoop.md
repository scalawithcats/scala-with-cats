## Project: Pygmy Hadoop

In a previous section we implemented a function `foldMap` that folded a `List` using an implicit monoid. In this project we're going to extend this idea to parallel processing.

If you have used Hadoop or otherwise worked in the "big data" field you will have heard of the [MapReduce](http://research.google.com/archive/mapreduce.html) programming model. MapReduce is a model for parallel data processing that is commonly used to process data cross tens or hundreds of machines. As the name suggests, it is built around a map phase, which is the same `map` function we know from Scala, and a reduce phase, which we usually call `fold`. (In Hadoop there is also a shuffle phase, which we are going to ignore.)

It should be fairly obvious we can apply `map` in parallel. In general we cannot parallelize `fold`, but if we are prepared to restrict the type of functions we allow in fold we can do so. What kind of restrictions should be apply? If the function we provide to `fold` is associative (so `(x + y) + z == x + (y + z)`, for some binary function `+`) we can perform our fold in any order so long as we preserve ordering on the sequence of elements we're processing. If we have an identity element (so `x + 0 == 0 + x` for any `x`) we can introduce the identity at any point to in our fold and know we won't affect the result.

If this sounds like a monoid, it's because it is a monoid. We're not the first to recognise this. The [monoid design pattern for MapReduce jobs](http://arxiv.org/abs/1304.7544) is at the core of recent big data systems such as Twitter's [Summingbird](https://github.com/twitter/summingbird).

In this project we're going to implement a very simple single-machine MapReduce. In fact, we're just going to parallelize `foldMap` and then look at some of more interesting monoids that are applicable for processing large data sets.

### FoldMap

Last time we saw `foldMap` we implemented it as follows:

~~~ scala
object FoldMap {
  implicit class ListFoldable[A](base: List[A]) {
    def foldMap[B : Monoid](f: A => B = (a: A) => a): B =
      base.foldLeft(mzero[B])(_ |+| f(_))
  }
}
~~~

To run the fold in parallel we need to change the implementation strategy. A simple strategy is to allocate as many threads as we have CPUs, and then evenly partition our sequence amongst the threads. When each thread completes we simply append the results together.

Scala provides some simple tools to distribute work amongst threads. We could in fact just use the [parallel collections library](http://docs.scala-lang.org/overviews/parallel-collections/overview.html) to implement a solution, but I want to go a bit lower level. You might have already used `Futures`. A `Future` models a computation that may not yet have a value. That is, it represents a value that will become available in the future. They are a good tool for this sort of job.


### Futures

To execute an operation in parallel we can construct a `Future` like so

~~~ scala
import scala.concurrent.Future
val future: Future[String] = Future { "construct this string in parallel!" }
~~~

We need to have an implicit `ExecutionContext` in scope, which determines which thread pool runs the operation. The default `ExecutionContext` is a good choice. We get hold of it with

~~~ scala
import scala.concurrent.ExecutionContext.Implicits.global
~~~

We sequence operations on a `Future` using the familiar `map` and `flatMap` methods.

If we have a sequence containing `Futures` we can convert them into a `Future` of a sequence using the method `Future.sequence`.

~~~ scala
scala> Future.sequence(Seq(Future(1), Future(2), Future(3)))
res27: scala.concurrent.Future[Seq[Int]] = scala.concurrent.impl.Promise$DefaultPromise@3ded31af
~~~

Finally, if we want to block on a `Future` till a result is available we can use `Await.result`.

~~~ scala
import scala.concurrent.duration.Duration
Await.result(Future(1), Duration.Inf) // Wait forever till a result arrives
~~~


### Partitioning Sequences

We can partition a sequence (actually anything that implements `Iterable`) using the `grouped` method.

~~~ scala
scala> Seq(1, 2, 3, 4).grouped(2)
res22: Iterator[Seq[Int]] = non-empty iterator

scala> Seq(1, 2, 3, 4).grouped(2).toList
res23: List[Seq[Int]] = List(List(1, 2), List(3, 4))
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
My solution can be found in the accompanying code repository in `monoid/src/main/scala/parallel`. The important bits are repeated below.

I found very little difference between parallel and sequential code in terms of performance. This could be an artifact of the benchmarks I used, my hardware, or the overhead of constructing and running parallel code.

~~~ scala
object FoldMap {
  def foldMapP[A, B : Monoid](iter: Iterable[A])(f: A => B = (a: A) => a)(implicit ec: ExecutionContext): B = {
    val nCores: Int = Runtime.getRuntime().availableProcessors()
    val groupSize: Int = (iter.size.toDouble / nCores.toDouble).ceil.round.toInt

    val groups = iter.grouped(groupSize)
    val futures: Iterator[Future[B]] = groups map { group =>
      Future { group.foldLeft(mzero[B])(_ |+| f(_)) }
    }
    val result: Future[B] = Future.sequence(futures) map { iterable =>
      iterable.foldLeft(mzero[B])(_ |+| _)
    }

    Await.result(result, Duration.Inf)
  }

  def foldMap[A, B : Monoid](iter: Iterable[A])(f: A => B = (a: A) => a): B =
    iter.foldLeft(mzero[B])(_ |+| f(_))

  implicit class IterableFoldMappable[A](iter: Iterable[A]) {
    def foldMapP[B : Monoid](f: A => B = (a: A) => a)(implicit ec: ExecutionContext): B =
      FoldMap.foldMap(iter)(f)

    def foldMap[B : Monoid](f: A => B = (a: A) => a): B =
      FoldMap.foldMap(iter)(f)
  }
}
~~~
</div>


### More Monoids

The monoid instances we have considered so far are very simple. Much more complex and interesting monoids are possible. For example, the [HyperLogLog](http://en.wikipedia.org/wiki/HyperLogLog) algorithm is used to approximate the number of distinct elements in a collection and forms a monoid. It is extremely commonly used in big data applications due to its high accuracy and small storage requirements. Other algorithms for which there is a monoid include the [Bloom filter](http://en.wikipedia.org/wiki/Bloom_filter), a space-efficient probabilistic set, [stochastic gradient descent](http://en.wikipedia.org/wiki/Stochastic_gradient_descent), commonly used to train machine learning models, and the [Top-K algorithm](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.114.9563), used to find the *K* frequent items in a collection. Scala implementations of all these algorithms can be found in [Algebird](https://github.com/twitter/algebird).
