## The Eval Monad {#sec:monads:eval}

[`cats.Eval`][cats.Eval] is a monad that allows us to
abstract over different *models of evaluation*.
We typically hear of two such models: *eager* and *lazy*.
`Eval` throws in a further distinction of
whether or not a result is *memoized*.

### Eager, Lazy, Memoized, Oh My!

What do these terms mean?

*Eager* computations happen immediately
whereas *lazy* computations happen on access.
*Memoized* computations are run once on first access,
after which the results are cached.

For example, Scala `vals` are eager and memoized.
We can see this using a computation with a visible side-effect.
In the following example,
the code to compute the value of `x`
happens at the definition site
rather than on access (eager).
Accessing `x` recalls the stored value
without re-running the code (memoized).

```tut:book
val x = {
  println("Computing X")
  math.random
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
  math.random
}

y // first access
y // second access
```

Last but not least,
`lazy vals` are lazy and memoized.
The code to compute `z` below
is not run until we access it
for the first time (lazy).
The result is then cached
and re-used on subsequent accesses (memoized):

```tut:book
lazy val z = {
  println("Computing Z")
  math.random
}

z // first access
z // second access
```

### Eval's Models of Evaluation

`Eval` has three subtypes: `Now`, `Later`, and `Always`.
We construct these with three constructor methods,
which create instances of the three classes
and return them typed as `Eval`:

```tut:book:silent
import cats.Eval
```

```tut:book
val now = Eval.now(math.random + 1000)
val later = Eval.later(math.random + 2000)
val always = Eval.always(math.random + 3000)
```

We can extract the result of an `Eval`
using its `value` method:

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
  math.random
}

x.value // first access
x.value // second access
```

`Eval.always` captures a lazy computation,
similar to a `def`:

```tut:book
val y = Eval.always {
  println("Computing Y")
  math.random
}

y.value // first access
y.value // second access
```

Finally, `Eval.later` captures a lazy, memoized computation,
similar to a `lazy val`:

```tut:book
val z = Eval.later {
  println("Computing Z")
  math.random
}

z.value // first access
z.value // second access
```

The three behaviours are summarized below:

-----------------------------------------------------------------------
Scala              Cats                      Properties
------------------ ------------------------- --------------------------
`val`              `Now`                     eager, memoized
`lazy val`         `Later`                   lazy, memoized
`def`              `Always`                  lazy, not memoized
------------------ ------------------------- --------------------------

### Eval as a Monad

Like all monads, `Eval's` `map` and `flatMap` methods add computations to a chain.
In this case, however, the chain is stored explicitly as a list of functions.
The functions aren't run until we call
`Eval's` `value` method to request a result:

```tut:book
val greeting = Eval.
  always { println("Step 1"); "Hello" }.
  map { str => println("Step 2"); s"$str world" }

greeting.value
```

Note that, while the semantics of
the originating `Eval` instances are maintained,
mapping functions are always
called lazily on demand (`def` semantics):

```tut:book
val ans = for {
  a <- Eval.now { println("Calculating A"); 40 }
  b <- Eval.always { println("Calculating B"); 2 }
} yield {
  println("Adding A and B")
  a + b
}

ans.value // first access
ans.value // second access
```

`Eval` has a `memoize` method that
allows us to memoize a chain of computations.
The result of the chain up to the call to `memoize` is cached,
whereas calculations after the call retain their original semantics:

```tut:book
val saying = Eval.
  always { println("Step 1"); "The cat" }.
  map { str => println("Step 2"); s"$str sat on" }.
  memoize.
  map { str => println("Step 3"); s"$str the mat" }

saying.value // first access
saying.value // second access
```

### Trampolining and *Eval.defer*

One useful property of `Eval`
is that its `map` and `flatMap` methods are *trampolined*.
This means we can nest calls to `map` and `flatMap` arbitrarily
without consuming stack frames.
We call this property *"stack safety"*.

For example, consider this function for calculating factorials:

```tut:book:silent
def factorial(n: BigInt): BigInt =
  if(n == 1) n else n * factorial(n - 1)
```

It is relatively easy to make this method stack overflow:

```scala
factorial(50000)
// java.lang.StackOverflowError
//   ...
```

We can rewrite the method using `Eval` to make it stack safe:

```tut:book:silent
def factorial(n: BigInt): Eval[BigInt] =
  if(n == 1) {
    Eval.now(n)
  } else {
    factorial(n - 1).map(_ * n)
  }
```

```scala
factorial(50000).value
// java.lang.StackOverflowError
//   ...
```

Oops! That didn't work---our stack still blew up!
This is because we're still making all the recursive calls to `factorial`
before we start working with `Eval's` `map` method.
We can work around this using `Eval.defer`,
which takes an existing instance of `Eval` and defers its evaluation.
The `defer` method is trampolined like `map` and `flatMap`,
so we can use it as a quick way to make an existing operation stack safe:

```tut:book:silent
def factorial(n: BigInt): Eval[BigInt] =
  if(n == 1) {
    Eval.now(n)
  } else {
    Eval.defer(factorial(n - 1).map(_ * n))
  }
```

```tut:book
factorial(50000).value
```

`Eval` is a useful tool to enforce stack safety
when working on very large computations and data structures.
However, we must bear in mind that trampolining is not free.
It avoids consuming stack by creating a chain of function objects on the heap.
There are still limits on how deeply we can nest computations,
but they are bounded by the size of the heap rather than the stack.

### Exercise: Safer Folding using Eval

The naive implementation of `foldRight` below is not stack safe.
Make it so using `Eval`:

```tut:book:silent
def foldRight[A, B](as: List[A], acc: B)(fn: (A, B) => B): B =
  as match {
    case head :: tail =>
      fn(head, foldRight(tail, acc)(fn))
    case Nil =>
      acc
  }
```

<div class="solution">
The easiest way to fix this is
to introduce a helper method called `foldRightEval`.
This is essentially our original method
with every occurrence of `B` replaced with `Eval[B]`,
and a call to `Eval.defer` to protect the recursive call:

```tut:book:silent
import cats.Eval

def foldRightEval[A, B](as: List[A], acc: Eval[B])
    (fn: (A, Eval[B]) => Eval[B]): Eval[B] =
  as match {
    case head :: tail =>
      Eval.defer(fn(head, foldRightEval(tail, acc)(fn)))
    case Nil =>
      acc
  }
```

We can redefine `foldRight` simply in terms of `foldRightEval`
and the resulting method is stack safe:

```tut:book:silent
def foldRight[A, B](as: List[A], acc: B)(fn: (A, B) => B): B =
  foldRightEval(as, Eval.now(acc)) { (a, b) =>
    b.map(fn(a, _))
  }.value
```

```tut:book
foldRight((1 to 100000).toList, 0L)(_ + _)
```
</div>
