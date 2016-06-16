## *Eval* {#eval}

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
which create instances of the three classes and return them as instance of `Eval`:

```scala
import cats.Eval
// import cats.Eval

val now    = Eval.now(1 + 2)
// now: cats.Eval[Int] = Now(3)

val later  = Eval.later(3 + 4)
// later: cats.Eval[Int] = cats.Later@686d434b

val always = Eval.always(5 + 6)
// always: cats.Eval[Int] = cats.Always@5b975a32
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
// y: cats.Eval[Int] = cats.Always@602275ed

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
// z: cats.Eval[Int] = cats.Later@4bca91fa

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
| Not memoized     | `def`, `Eval.always`    | <span>-</span>           |
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
// greeting: cats.Eval[String] = cats.Eval$$anon$8@2a912b22

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
// ans: cats.Eval[Int] = cats.Eval$$anon$8@44c7d73f

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
// saying: cats.Eval[String] = cats.Eval$$anon$8@14b8642e

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
The `add1` method below prints the stack depth and creates an `Option`:

```scala
def stackDepth: Int =
  new Exception().getStackTrace.length
// stackDepth: Int

def add1(n: Int): Option[Int] = {
  println(s"Stack depth when calculting $n + 1: $stackDepth")
  Some(n + 1)
}
// add1: (n: Int)Option[Int]
```

If we write code like the following,
we can see that the stack depth increases as we next `flatMaps`:

```scala
for {
  a <- add1(0)
  b <- add1(a)
  c <- add1(b)
  d <- add1(c)
} yield a + b + c + d
// Stack depth when calculting 0 + 1: 1024
// Stack depth when calculting 1 + 1: 1024
// Stack depth when calculting 2 + 1: 1024
// Stack depth when calculting 3 + 1: 1024
// res20: Option[Int] = Some(10)
```

If we nest calls to `flatMap` deep enough,
we will eventually get a `StackOverflowError`.
This can happen when, for example,
we are folding over an incredibly long sequence.

Now let's consider the same code rewritten using `Eval`:

```scala
def stackDepth: Int =
  new Exception().getStackTrace.length
// stackDepth: Int

def add1(n: Int): Eval[Int] = {
  println(s"Stack depth when calculting $n + 1: $stackDepth")
  Eval.later(n + 1)
}
// add1: (n: Int)cats.Eval[Int]
```

We're using `Eval.Later` here,
but the behaviour is the same with all evaluation strategies:

```scala
val eval = for {
  a <- add1(0)
  b <- add1(a)
  c <- add1(b)
  d <- add1(c)
} yield a + b + c + d
// Stack depth when calculting 0 + 1: 1024
// eval: cats.Eval[Int] = cats.Eval$$anon$8@13e61cd3

eval.value
// Stack depth when calculting 1 + 1: 1024
// Stack depth when calculting 2 + 1: 1024
// Stack depth when calculting 3 + 1: 1024
// res21: Int = 10
```

We don't see all of the messages
until we call `value` to kick off the calculation.
However, when we do, we see that the stack depth is consistent throughout.

We can use `Eval` as a mechanism to prevent to prevent stack overflows
when working on very large data structures.
However, we should bear in mind that trampolining is not free.
It effectively avoids consuming stack by
creating a linked list of function calls on the heap.
There are still limits on how deeply we can nest computations,
but they are bounded by the size of the heap rather than the stack.

<!--
TODO: Process these and check we're covering everything important:

- https://github.com/typelevel/cats/blob/master/core/src/main/scala/cats/Eval.scala
- http://eed3si9n.com/herding-cats/Eval.html
- Erik's talk from Typelevel Philly (once the video is up)
-->
