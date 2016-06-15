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

`Eval` has three constructors,
each of which creates an instance
that captures a computation using a different evaluation model.
In each case we retrieve the result of the computation using the `value` method.

`Eval.now` captures a value *right now*.
Its semantics are similar to a `val`---eager and memoized:

```tut:book
import cats.Eval

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
| Not memoized     | `def`, `Eval.always`    | <span>-</span>           |
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
val saying = Eval.always { println("Step 1") ; "The cat" }.
  map { str => println("Step 2") ; str + " sat on" }.
  memoize.
  map { str => println("Step 3") ; str + " the mat" }

saying.value // first access
saying.value // second access
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
