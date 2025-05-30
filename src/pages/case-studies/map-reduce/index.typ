#import "../../stdlib.typ": info, warning, solution
= Case Study: Map-Reduce 
<sec:map-reduce>


<!--
TODO:

- DONE - talk about map-reduce - it's just foldMap
- DONE - introduce/reimplement foldMap
- DONE - implement parallelFoldMap to mimic map-reduce
  - DONE - mention that we're specifically imitating multi-machine
           map-reduce where we need to split data between machines
           in large blocks
  - DONE - implement in terms of our foldMap first
  - DONE - then implement in terms of Cats' foldMap
  - DONE - talk about traverse
- summary
  - DONE - real-world map-reduce has communication costs
  - DONE - multi-cpu map-reduce doesn't have communication costs
  - DONE - parallelFoldMap mimics multi-machine
  - DONE - our final version of parallelFoldMap (based on traverse) is far simpler
  - talk about substitution and the things it doesn't model:
    - performance
    - parallelism
    - side-effects (future starts immediately)
    - etc...

TODO:

- DONE - drop the current foldMapM stuff
- DONE - maybe move it elsewhere
-->

In this case study we're going to implement
a simple-but-powerful parallel processing framework
using `Monoids`, `Functors`, and a host of other goodies.

If you have used Hadoop or otherwise worked in "big data"
you will have heard of [MapReduce][link-map-reduce],
which is a programming model for doing parallel data processing
across clusters of machines (aka "nodes").
As the name suggests, the model is built around a _map_ phase,
which is the same `map` function we know
from Scala and the `Functor` type class, and a _reduce_ phase,
which we usually call `fold`[^hadoop-shuffle] in Scala.

[^hadoop-shuffle]: In Hadoop there is also a shuffle phase
that we will ignore here.

== Parallelizing *map* and *fold*


Recall the general signature for `map` is
to apply a function `A => B` to a `F[A]`,
returning a `F[B]`:

!#link("generic-map.svg"), caption: [Type chart: functor map]
<fig:map-reduce:functor-type-chart>

`map` transforms each individual element in a sequence independently.
We can easily parallelize `map` because
there are no dependencies between
the transformations applied to different elements
(the type signature of the function `A => B` shows us this,
assuming we don't use side-effects not reflected in the types).

What about `fold`?
We can implement this step with an instance of `Foldable`.
Not every functor also has an instance of foldable
but we can implement a map-reduce system
on top of any data type that has both of these type classes.
Our reduction step becomes a `foldLeft`
over the results of the distributed `map`.

!#link("generic-foldleft.svg"), caption: [Type chart: fold]
<fig:map-reduce:foldleft-type-chart>

By distributing the reduce step
we lose control over the order of traversal.
Our overall reduction may not be entirely left-to-right---we
may reduce left-to-right across several subsequences
and then combine the results.
To ensure correctness we need
a reduction operation that is _associative_:

```scala
reduce(a1, reduce(a2, a3)) == reduce(reduce(a1, a2), a3)
```

If we have associativity,
we can arbitrarily distribute work
between our nodes provided the subsequences
at every node stay in the same order as the initial dataset.

Our fold operation requires us to seed the computation
with an element of type `B`.
Since fold may be split
into an arbitrary number of parallel steps,
the seed should not affect the result of the computation.
This naturally requires the seed to be an _identity_ element:

```scala
reduce(seed, a1) == reduce(a1, seed) == a1
```

In summary, our parallel fold will yield the correct results if:

- we require the reducer function to be associative;
- we seed the computation with the identity of this function.

What does this pattern sound like?
That's right, we've come full circle back to `Monoid`,
the first type class we discussed in this book.
We are not the first to recognise the importance of monoids.
The [monoid design pattern for map-reduce jobs][link-map-reduce-monoid]
is at the core of recent big data systems
such as Twitter's [Summingbird][link-summingbird].

In this project we're going to implement
a very simple single-machine map-reduce.
We'll start by implementing a method called `foldMap`
to model the data-flow we need.

== Implementing *foldMap*


We saw `foldMap` briefly back when we covered `Foldable`.
It is one of the derived operations that sits
on top of `foldLeft` and `foldRight`.
However, rather than use `Foldable`,
we will re-implement `foldMap` here ourselves
as it will provide useful insight into
the structure of map-reduce.

Start by writing out the signature of `foldMap`.
It should accept the following parameters:

 - a sequence of type `Vector[A]`;
 - a function of type `A => B`, where there is a `Monoid` for `B`;

You will have to add implicit parameters or context bounds
to complete the type signature.

#solution[
```scala mdoc:silent
import cats.Monoid

/** Single-threaded map-reduce function.
  * Maps `func` over `values` and reduces using a `Monoid[B]`.
  */
def foldMap[A, B: Monoid](values: Vector[A])(func: A => B): B =
  ???
```
]

Now implement the body of `foldMap`.
Use the flow chart in @fig:map-reduce:fold-map as a guide
to the steps required:

+ start with a sequence of items of type `A`;
+ map over the list to produce a sequence of items of type `B`;
+ use the `Monoid` to reduce the items to a single `B`.

#figure(image("fold-map.svg"), caption: [_foldMap_ algorithm])
<fig:map-reduce:fold-map>

Here's some sample output for reference:

```scala mdoc:invisible:reset
import cats.Monoid
import cats.syntax.semigroup._ // for |+|

def foldMap[A, B: Monoid](values: Vector[A])(func: A => B): B =
  values.foldLeft(Monoid[B].empty)(_ |+| func(_))
```

```scala mdoc:silent
import cats.instances.int._ // for Monoid
```

```scala mdoc
foldMap(Vector(1, 2, 3))(identity)
```

```scala mdoc:silent
import cats.instances.string._ // for Monoid
```

```scala mdoc
// Mapping to a String uses the concatenation monoid:
foldMap(Vector(1, 2, 3))(_.toString + "! ")

// Mapping over a String to produce a String:
foldMap("Hello world!".toVector)(_.toString.toUpperCase)
```

#solution[
We have to modify the type signature to accept a `Monoid` for `B`.
With that change we can use the `Monoid` `empty` and `|+|` syntax
as described in @sec:monoid-syntax:

```scala mdoc:reset:silent
import cats.Monoid
import cats.syntax.semigroup._ // for |+|

def foldMap[A, B : Monoid](as: Vector[A])(func: A => B): B =
  as.map(func).foldLeft(Monoid[B].empty)(_ |+| _)
```

We can make a slight alteration to this code to do everything in one step:

```scala mdoc:reset:invisible
import cats.Monoid
import cats.syntax.semigroup._
```
```scala mdoc:silent
def foldMap[A, B : Monoid](as: Vector[A])(func: A => B): B =
  as.foldLeft(Monoid[B].empty)(_ |+| func(_))
```
]

== Parallelising *foldMap*


Now we have a working single-threaded implementation of `foldMap`,
let's look at distributing work to run in parallel.
We'll use our single-threaded version of `foldMap` as a building block.

We'll write a multi-CPU implementation
that simulates the way we would distribute work
in a map-reduce cluster as shown in @fig:map-reduce:parallel-fold-map:

+ we start with an initial list of all the data we need to process;
+ we divide the data into batches, sending one batch to each CPU;
+ the CPUs run a batch-level map phase in parallel;
+ the CPUs run a batch-level reduce phase in parallel,
   producing a local result for each batch;
+ we reduce the results for each batch to a single final result.

#figure(image("parallel-fold-map.svg"), caption: [_parallelFoldMap_ algorithm])
<fig:map-reduce:parallel-fold-map>

Scala provides some simple tools
to distribute work amongst threads.
We could use the [parallel collections library][link-parallel-collections]
to implement a solution,
but let's challenge ourselves by diving a bit deeper
and implementing the algorithm ourselves using `Futures`.

=== *Futures*, Thread Pools, and ExecutionContexts


We already know a fair amount about
the monadic nature of `Futures`.
Let's take a moment for a quick recap,
and to describe how Scala futures
are scheduled behind the scenes.

`Futures` run on a thread pool,
determined by an implicit `ExecutionContext` parameter.
Whenever we create a `Future`,
whether through a call to `Future.apply` or some other combinator,
we must have an implicit `ExecutionContext` in scope:

```scala mdoc:silent
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
```

```scala mdoc
val future1 = Future {
  (1 to 100).toList.foldLeft(0)(_ + _)
}

val future2 = Future {
  (100 to 200).toList.foldLeft(0)(_ + _)
}
```

In this example we've imported a `ExecutionContext.Implicits.global`.
This default context allocates a thread pool
with one thread per CPU in our machine.
When we create a `Future`
the `ExecutionContext` schedules it for execution.
If there is a free thread in the pool,
the `Future` starts executing immediately.
Most modern machines have at least two CPUs,
so in our example it is likely that `future1` and `future2`
will execute in parellel.

Some combinators create new `Futures`
that schedule work based on the results of other `Futures`.
The `map` and `flatMap` methods, for example,
schedule computations that run as soon as
their input values are computed and a CPU is available:

```scala mdoc
val future3 = future1.map(_.toString)

val future4 = for {
  a <- future1
  b <- future2
} yield a + b
```

As we saw in @sec:traverse,
we can convert a `List[Future[A]]` to a `Future[List[A]]`
using `Future.sequence`:

```scala mdoc
Future.sequence(List(Future(1), Future(2), Future(3)))
```

or an instance of `Traverse`:

```scala mdoc:silent
import cats.instances.future._ // for Applicative
import cats.instances.list._   // for Traverse
import cats.syntax.traverse._  // for sequence
```

```scala mdoc
List(Future(1), Future(2), Future(3)).sequence
```

An `ExecutionContext` is required in either case.
Finally, we can use `Await.result`
to block on a `Future` until a result is available:

```scala mdoc:silent
import scala.concurrent._
import scala.concurrent.duration._
```

```scala mdoc
Await.result(Future(1), 1.second) // wait for the result
```

There are also `Monad` and `Monoid` implementations for `Future`
available from `cats.instances.future`:

```scala mdoc:silent
import cats.{Monad, Monoid}
import cats.instances.int._    // for Monoid
import cats.instances.future._ // for Monad and Monoid

Monad[Future].pure(42)

Monoid[Future[Int]].combine(Future(1), Future(2))
```

=== Dividing Work


Now we've refreshed our memory of `Futures`,
let's look at how we can divide work into batches.
We can query the number of available CPUs on our machine
using an API call from the Java standard library:

```scala mdoc
Runtime.getRuntime.availableProcessors
```

We can partition a sequence
(actually anything that implements `Vector`)
using the `grouped` method.
We'll use this to split off batches of work for each CPU:

```scala mdoc
(1 to 10).toList.grouped(3).toList
```

=== Implementing *parallelFoldMap*


Implement a parallel version of `foldMap` called `parallelFoldMap`.
Here is the type signature:

```scala mdoc:silent
def parallelFoldMap[A, B : Monoid]
      (values: Vector[A])
      (func: A => B): Future[B] = ???
```

Use the techniques described above to
split the work into batches, one batch per CPU.
Process each batch in a parallel thread.
Refer back to @fig:map-reduce:parallel-fold-map
if you need to review the overall algorithm.

For bonus points, process the batches for each CPU
using your implementation of `foldMap` from above.

#solution[
Here is an annotated solution that
splits out each `map` and `fold`
into a separate line of code:

```scala mdoc:invisible:reset
import cats._
import cats.implicits._
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global
```
```scala mdoc:silent
def parallelFoldMap[A, B: Monoid]
      (values: Vector[A])
      (func: A => B): Future[B] = {
  // Calculate the number of items to pass to each CPU:
  val numCores  = Runtime.getRuntime.availableProcessors
  val groupSize = (1.0 * values.size / numCores).ceil.toInt

  // Create one group for each CPU:
  val groups: Iterator[Vector[A]] =
    values.grouped(groupSize)

  // Create a future to foldMap each group:
  val futures: Iterator[Future[B]] =
    groups map { group =>
      Future {
        group.foldLeft(Monoid[B].empty)(_ |+| func(_))
      }
    }

  // foldMap over the groups to calculate a final result:
  Future.sequence(futures) map { iterable =>
    iterable.foldLeft(Monoid[B].empty)(_ |+| _)
  }
}

val result: Future[Int] =
  parallelFoldMap((1 to 1000000).toVector)(identity)
```

```scala mdoc
Await.result(result, 1.second)
```

We can re-use our definition of `foldMap` for a more concise solution.
Note that the local maps and reduces in steps 3 and 4 of
@fig:map-reduce:parallel-fold-map
are actually equivalent to a single call to `foldMap`,
shortening the entire algorithm as follows:

```scala mdoc:reset:invisible
import cats._
import cats.implicits._
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global
def foldMap[A, B : Monoid](as: Vector[A])(func: A => B): B =
  as.foldLeft(Monoid[B].empty)(_ |+| func(_))
```
```scala mdoc:silent
def parallelFoldMap[A, B: Monoid]
      (values: Vector[A])
      (func: A => B): Future[B] = {
  val numCores  = Runtime.getRuntime.availableProcessors
  val groupSize = (1.0 * values.size / numCores).ceil.toInt

  val groups: Iterator[Vector[A]] =
    values.grouped(groupSize)

  val futures: Iterator[Future[B]] =
    groups.map(group => Future(foldMap(group)(func)))

  Future.sequence(futures) map { iterable =>
    iterable.foldLeft(Monoid[B].empty)(_ |+| _)
  }
}

val result: Future[Int] =
  parallelFoldMap((1 to 1000000).toVector)(identity)
```

```scala mdoc
Await.result(result, 1.second)
```
]

=== *parallelFoldMap* with more Cats


Although we implemented `foldMap` ourselves above,
the method is also available as part of the `Foldable`
type class we discussed in @sec:foldable.

Reimplement `parallelFoldMap` using Cats'
`Foldable` and `Traverseable` type classes.

#solution[
We'll restate all of the necessary imports for completeness:

```scala mdoc:silent:reset
import cats.Monoid

import cats.instances.int._    // for Monoid
import cats.instances.future._ // for Applicative and Monad
import cats.instances.vector._ // for Foldable and Traverse

import cats.syntax.foldable._  // for combineAll and foldMap
import cats.syntax.traverse._  // for traverse

import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global
```

Here's the implementation of `parallelFoldMap`
delegating as much of the method body to Cats as possible:

```scala mdoc:silent
def parallelFoldMap[A, B: Monoid]
      (values: Vector[A])
      (func: A => B): Future[B] = {
  val numCores  = Runtime.getRuntime.availableProcessors
  val groupSize = (1.0 * values.size / numCores).ceil.toInt

  values
    .grouped(groupSize)
    .toVector
    .traverse(group => Future(group.toVector.foldMap(func)))
    .map(_.combineAll)
}
```

```scala mdoc:silent
val future: Future[Int] =
  parallelFoldMap((1 to 1000).toVector)(_ * 1000)
```

```scala mdoc
Await.result(future, 1.second)
```

The call to `vector.grouped` returns an `Iterable[Iterator[Int]]`.
We sprinkle calls to `toVector` through the code
to convert the data back to a form that Cats can understand.
The call to `traverse` creates a `Future[Vector[Int]]`
containing one `Int` per batch.
The call to `map` then combines the `match` using
the `combineAll` method from `Foldable`.
]

== Summary


In this case study we implemented
a system that imitates map-reduce
as performed on a cluster.
Our algorithm followed three steps:

+ batch the data and send one batch to each "node";
+ perform a local map-reduce on each batch;
+ combine the results using monoid addition.

Our toy system emulates the batching behaviour
of real-world map-reduce systems such as Hadoop.
However, in reality we are running all of our work
on a single machine where communcation between nodes is negligible.
We don't actually need to batch data
to gain efficient parallel processing of a list.
We can simply map using a `Functor` and reduce using a `Monoid`.

Regardless of the batching strategy,
mapping and reducing with `Monoids`
is a powerful and general framework
that isn't limited to simple tasks
like addition and string concatenation.
Most of the tasks data scientists perform
in their day-to-day analyses can be cast as monoids.
There are monoids for all the following:

- approximate sets such as the Bloom filter;
- set cardinality estimators,
  such as the HyperLogLog algorithm;
- vectors and vector operations
  like stochastic gradient descent;
- quantile estimators such as the t-digest

to name but a few.
