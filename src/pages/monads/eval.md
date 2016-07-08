## The *Eval* Monad {#eval}

[`cats.Eval`][cats.Eval] is a monad that allows us to
abstract over different *models of evaluation*.
We typically hear of two such models: *eager* and *lazy*.
`Eval` throws in a further distinction of
*memoized* and *unmemoized* to create three models of evaluation:

 - *now*---evaluated once immediately (equivalent to `val`);
 - *later*---evaluated once when value is needed (equivalent to `lazy val`);
 - *always*---evaluated every time value is needed (equivalent to `def`).

### Eager, lazy, memoized, oh my!

What do these terms mean?

*Eager* computations happen immediately,
whereas *lazy* computations happen on access.

For example, Scala `vals` are eager definitions.
We can see this using a computation with a visible side-effect.
In the following example,
the code to compute the value of `x` happens eagerly at the definition site.
Accessing `x` simply recalls the stored value without re-running the code.

```scala
val x = {
  println("Computing X")
  1 + 1
}
// Computing X
// x: Int = 2

x // first access
// res0: Int = 2

x // second access
// res1: Int = 2
```

By contrast, `defs` are lazy and not memoized.
The code to compute `y` below
is not run until we access it (lazy),
and is re-run on every access (not memoized):

```scala
def y = {
  println("Computing Y")
  1 + 1
}
// y: Int

y // first access
// Computing Y
// res2: Int = 2

y // second access
// Computing Y
// res3: Int = 2
```

Last but not least, `lazy vals` are eager and memoized.
The code to compute `z` below
is not run until we access it for the first time (lazy).
The result is then cached and re-used on subsequent accesses (memoized):

```scala
lazy val z = {
  println("Computing Z")
  1 + 1
}
// z: Int = <lazy>

z // first access
// Computing Z
// res4: Int = 2

z // second access
// res5: Int = 2
```

### Eval's models of evaluation

`Eval` has three subtypes: `Eval.Now`, `Eval.Later`, and `Eval.Always`.
We construct these with three constructor methods,
which create instances of the three classes and return them typed as `Eval`:

```scala
import cats.Eval
// import cats.Eval

val now    = Eval.now(1 + 2)
// now: cats.Eval[Int] = Now(3)

val later  = Eval.later(3 + 4)
// later: cats.Eval[Int] = cats.Later@187a8980

val always = Eval.always(5 + 6)
// always: cats.Eval[Int] = cats.Always@42c26b21
```

We can extract the result of an `Eval` using its `value` method:

```scala
now.value
// res6: Int = 3

later.value
// res7: Int = 7

always.value
// res8: Int = 11
```

Each type of `Eval` calculates its result
using one of the evaluation models defined above.
`Eval.now` captures a value *right now*.
Its semantics are similar to a `val`---eager and memoized:

```scala
val x = Eval.now {
  println("Computing X")
  1 + 1
}
// Computing X
// x: cats.Eval[Int] = Now(2)

x.value // first access
// res9: Int = 2

x.value // second access
// res10: Int = 2
```

`Eval.always` captures a lazy computation,
similar to a `def`:

```scala
val y = Eval.always {
  println("Computing Y")
  1 + 1
}
// y: cats.Eval[Int] = cats.Always@6c4d2b95

y.value // first access
// Computing Y
// res11: Int = 2

y.value // second access
// Computing Y
// res12: Int = 2
```

Finally, `Eval.later` captures a lazy computation and memoizes the result,
similar to a `lazy val`:

```scala
val z = Eval.later {
  println("Computing Z")
  1 + 1
}
// z: cats.Eval[Int] = cats.Later@5e36f3a9

z.value // first access
// Computing Z
// res13: Int = 2

z.value // second access
// res14: Int = 2
```

The three behaviours are summarized below:

+------------------+-------------------------+--------------------------+
|                  | Eager                   | Lazy                     |
+==================+=========================+==========================+
| Memoized         | `val`, `Eval.now`       | `lazy val`, `Eval.later` |
+------------------+-------------------------+--------------------------+
| Not memoized     | <span>-</span>          | `def`, `Eval.always`     |
+------------------+-------------------------+--------------------------+

### Eval as a Monad

`Eval's` `map` and `flatMap` methods add computations to a chain.
This is similar to the `map` and `flatMap` methods on `scala.concurrent.Future`,
except that the computations aren't run until we call `value` to obtain a result:

```scala
val greeting = Eval.always {
  println("Step 1")
  "Hello"
}.map { str =>
  println("Step 2")
  str + " world"
}
// greeting: cats.Eval[String] = cats.Eval$$anon$8@1c4d12e2

greeting.value
// Step 1
// Step 2
// res15: String = Hello world
```

Note that, while the semantics of the originating `Eval` instances are maintained,
mapping functions are always called lazily on demand (`def` semantics):

```scala
val ans = for {
  a <- Eval.now    { println("Calculating A") ; 40 }
  b <- Eval.always { println("Calculating B") ; 2  }
} yield {
  println("Adding A and B")
  a + b
}
// Calculating A
// ans: cats.Eval[Int] = cats.Eval$$anon$8@208bc236

ans.value // first access
// Calculating B
// Adding A and B
// res16: Int = 42

ans.value // second access
// Calculating B
// Adding A and B
// res17: Int = 42
```

We can use `Eval's` `memoize` method to memoize a chain of computations.
Calculations before the call to `memoize` are cached,
whereas calculations after the call retain their original semantics:

```scala
val saying = Eval.always { println("Step 1") ; "The cat" }.
  map { str => println("Step 2") ; str + " sat on" }.
  memoize.
  map { str => println("Step 3") ; str + " the mat" }
// saying: cats.Eval[String] = cats.Eval$$anon$8@16ccbf37

saying.value // first access
// Step 1
// Step 2
// Step 3
// res18: String = The cat sat on the mat

saying.value // second access
// Step 3
// res19: String = The cat sat on the mat
```

### Trampolining

One useful property of `Eval` is
that its `map` and `flatMap` methods are *trampolined*.
This means we can nest calls to `map` and `flatMap` arbitrarily
without consuming stack frames.
We call this property *"stack safety"*.

We'll illustrate this by comparing it to `Option`.
The `loopM` method below creates a loop through a monad's `flatMap`.

```scala
import cats.Monad
// import cats.Monad

import cats.syntax.flatMap._
// import cats.syntax.flatMap._

import scala.language.higherKinds
// import scala.language.higherKinds

def stackDepth: Int =
  Thread.currentThread.getStackTrace.length
// stackDepth: Int

def loopM[M[_] : Monad](m: M[Int], count: Int): M[Int] = {
  println(s"Stack depth $stackDepth")
  count match {
    case 0 => m
    case n => m.flatMap { _ => loopM(m, n - 1) }
  }
}
// loopM: [M[_]](m: M[Int], count: Int)(implicit evidence$1: cats.Monad[M])M[Int]
```

When we run `loopM` with an `Option` we can see the stack depth slowly increasing.
With a sufficiently high value of `count`, we would blow the stack:

```scala
import cats.instances.option._
// import cats.instances.option._

import cats.syntax.option._
// import cats.syntax.option._
```

```scala
loopM(1.some, 5)
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// res20: Option[Int] = Some(1)
```

Now let's see the same code rewritten using `Eval`.
The trampoline keeps the stack depth constant:

```scala
loopM(Eval.now(1), 5).value
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// Stack depth 1024
// res21: Int = 1
```

We see that this runs without issue.

We can use `Eval` as a mechanism to prevent to prevent stack overflows
when working on very large data structures.
However, we should bear in mind that trampolining is not free.
It effectively avoids consuming stack by
creating a chain of function calls on the heap.
There are still limits on how deeply we can nest computations,
but they are bounded by the size of the heap rather than the stack.

<!--
TODO: Process these and check we're covering everything important:

- https://github.com/typelevel/cats/blob/master/core/src/main/scala/cats/Eval.scala
- http://eed3si9n.com/herding-cats/Eval.html
- Erik's talk from Typelevel Philly (once the video is up)
-->
