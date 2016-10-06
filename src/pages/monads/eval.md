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

```tut:book
val x = {
  println("Computing X")
  1 + 1
}

x // first access
x // second access
```

By contrast, `defs` are lazy and not memoized.
The code to compute `y` below
is not run until we access it (lazy),
and is re-run on every access (not memoized):

```tut:book
def y = {
  println("Computing Y")
  1 + 1
}

y // first access
y // second access
```

Last but not least, `lazy vals` are eager and memoized.
The code to compute `z` below
is not run until we access it for the first time (lazy).
The result is then cached and re-used on subsequent accesses (memoized):

```tut:book
lazy val z = {
  println("Computing Z")
  1 + 1
}

z // first access
z // second access
```

### Eval's models of evaluation

`Eval` has three subtypes: `Eval.Now`, `Eval.Later`, and `Eval.Always`.
We construct these with three constructor methods,
which create instances of the three classes and return them typed as `Eval`:

```tut:book
import cats.Eval

val now    = Eval.now(1 + 2)
val later  = Eval.later(3 + 4)
val always = Eval.always(5 + 6)
```

We can extract the result of an `Eval` using its `value` method:

```tut:book
now.value
later.value
always.value
```

Each type of `Eval` calculates its result
using one of the evaluation models defined above.
`Eval.now` captures a value *right now*.
Its semantics are similar to a `val`---eager and memoized:

```tut:book
val x = Eval.now {
  println("Computing X")
  1 + 1
}

x.value // first access
x.value // second access
```

`Eval.always` captures a lazy computation,
similar to a `def`:

```tut:book
val y = Eval.always {
  println("Computing Y")
  1 + 1
}

y.value // first access
y.value // second access
```

Finally, `Eval.later` captures a lazy computation and memoizes the result,
similar to a `lazy val`:

```tut:book
val z = Eval.later {
  println("Computing Z")
  1 + 1
}

z.value // first access
z.value // second access
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

```tut:book
val greeting = Eval.always {
  println("Step 1")
  "Hello"
}.map { str =>
  println("Step 2")
  str + " world"
}

greeting.value
```

Note that, while the semantics of the originating `Eval` instances are maintained,
mapping functions are always called lazily on demand (`def` semantics):

```tut:book
val ans = for {
  a <- Eval.now    { println("Calculating A") ; 40 }
  b <- Eval.always { println("Calculating B") ; 2  }
} yield {
  println("Adding A and B")
  a + b
}

ans.value // first access
ans.value // second access
```

We can use `Eval's` `memoize` method to memoize a chain of computations.
Calculations before the call to `memoize` are cached,
whereas calculations after the call retain their original semantics:

```tut:book
val saying = Eval.always {
  println("Step 1")
  "The cat"
}.map { str =>
  println("Step 2")
  s"$str sat on"
}.memoize.map { str =>
  println("Step 3")
  s"$str the mat"
}

saying.value // first access
saying.value // second access
```

### Trampolining

One useful property of `Eval` is
that its `map` and `flatMap` methods are *trampolined*.
This means we can nest calls to `map` and `flatMap` arbitrarily
without consuming stack frames.
We call this property *"stack safety"*.

We'll illustrate this by comparing it to `Option`.
The `loopM` method below creates a loop through a monad's `flatMap`.

```tut:book:silent
import cats.Monad
import cats.syntax.flatMap._
import scala.language.higherKinds

def stackDepth: Int =
  Thread.currentThread.getStackTrace.length

def loopM[M[_] : Monad](m: M[Int], count: Int): M[Int] = {
  println(s"Stack depth $stackDepth")
  count match {
    case 0 => m
    case n => m.flatMap { _ => loopM(m, n - 1) }
  }
}
```

When we run `loopM` with an `Option` we can see the stack depth slowly increasing.
With a sufficiently high value of `count`, we would blow the stack:

```tut:book:silent
import cats.instances.option._
```

```tut:book
loopM(Option(1), 5)
```

<div class="callout callout-danger">
TODO: This isn't actually increasing the stack depth -.-
</div>

Now let's see the same code rewritten using `Eval`.
The trampoline keeps the stack depth constant:

```tut:book
loopM(Eval.now(1), 5).value
```

We see that this runs without issue.

We can use `Eval` as a mechanism to prevent to prevent stack overflows
when working on very large data structures.
However, we should bear in mind that trampolining is not free.
It effectively avoids consuming stack by
creating a chain of function calls on the heap.
There are still limits on how deeply we can nest computations,
but they are bounded by the size of the heap rather than the stack.

<div class="callout callout-danger">
TODO: Process these and check we're covering everything important:

- https://github.com/typelevel/cats/blob/master/core/src/main/scala/cats/Eval.scala
- http://eed3si9n.com/herding-cats/Eval.html
- Erik's talk from Typelevel Philly 2016 (once the video is up)
</div>