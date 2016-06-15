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

`Eval` has three constructors,
each of which creates an instance
that captures a computation using a different evaluation model.
In each case we retrieve the result of the computation using the `value` method.

`Eval.now` captures a value *right now*.
Its semantics are similar to a `val`---eager and memoized:

```scala
import cats.Eval
// import cats.Eval

val x = Eval.now {
  println("Computing X")
  1 + 1
}
// Computing X
// x: cats.Eval[Int] = Now(2)

x.value // first access
// res6: Int = 2

x.value // second access
// res7: Int = 2
```

`Eval.always` captures a lazy computation,
similar to a `def`:

```scala
val y = Eval.always {
  println("Computing Y")
  1 + 1
}
// y: cats.Eval[Int] = cats.Always@125fda3a

y.value // first access
// Computing Y
// res8: Int = 2

y.value // second access
// Computing Y
// res9: Int = 2
```

Finally, `Eval.later` captures a lazy computation and memoizes the result,
similar to a `lazy val`:

```scala
val z = Eval.later {
  println("Computing Z")
  1 + 1
}
// z: cats.Eval[Int] = cats.Later@7be37030

z.value // first access
// Computing Z
// res10: Int = 2

z.value // second access
// res11: Int = 2
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
// greeting: cats.Eval[String] = cats.Eval$$anon$8@5dba2d2e

greeting.value
// Step 1
// Step 2
// res12: String = Hello world
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
// ans: cats.Eval[Int] = cats.Eval$$anon$8@1af12a4c

ans.value // first access
// Calculating B
// Adding A and B
// res13: Int = 42

ans.value // second access
// Calculating B
// Adding A and B
// res14: Int = 42
```

We can use `Eval's` `memoize` method to memoize a chain of computations.
Calculations before the call to `memoize` are cached,
whereas calculations after the call retain their original semantics:

```scala
val saying = Eval.always { println("Step 1") ; "The cat" }.
  map { str => println("Step 2") ; str + " sat on" }.
  memoize.
  map { str => println("Step 3") ; str + " the mat" }
// saying: cats.Eval[String] = cats.Eval$$anon$8@43b2fec8

saying.value // first access
// Step 1
// Step 2
// Step 3
// res15: String = The cat sat on the mat

saying.value // second access
// Step 3
// res16: String = The cat sat on the mat
```

### Trampolining

<div class="callout callout-danger">
TODO:

- Discuss trampolining
- Can we do it without discussing foldRight on Foldable?
- Maybe show a stack explosion
</div>

<!--
### Exercises

<div class="callout callout-danger">
TODO:

- Exercises
</div>
-->

<!--
TODO: Process these and check we're covering everything important:

- https://github.com/typelevel/cats/blob/master/core/src/main/scala/cats/Eval.scala
- http://eed3si9n.com/herding-cats/Eval.html
- Erik's talk from Typelevel Philly (once the video is up)
-->
