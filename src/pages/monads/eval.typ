#import "../stdlib.typ": info, warning, exercise, solution
== The Eval Monad 
<sec:monads:eval>


`cats.Eval` is a monad that allows us to
abstract over different *models of evaluation*.
We first met this concept, also known as evaluation strategies, in @sec:codata-structural.
We typically talk of two such models: *eager* and *lazy*,
also called *call-by-value* and *call-by-name* respectively.
`Eval` also allows for a result to be *memoized*,
which gives us *call-by-need* evaluation.

`Eval` is also *stack-safe*,
which means we can use it in very deep recursions
without blowing up the stack.


=== Eager, Lazy, Memoized, Oh My!

What do these terms for models of evaluation mean?
Let's see some examples.

Let's first look at Scala `vals`.
We can see the evaluation model using
a computation with a visible side-effect.
In the following example,
the code to compute the value of `x`
happens at the place where it is defined
rather than on access.
Accessing `x` recalls the stored value
without re-running the code.

```scala mdoc
val x = {
  println("Computing X")
  math.random()
}

x // first access
x // second access
```

This is an example of call-by-value evaluation:

- the computation is evaluated at the point where it is defined (eager); and
- the computation is evaluated once (memoized).


Let's look at an example using a `def`.
The code to compute `y` below
is not run until we use it,
and is re-run on every access:

```scala mdoc
def y = {
  println("Computing Y")
  math.random()
}

y // first access
y // second access
```

These are the properties of call-by-name evaluation:

- the computation is evaluated at the point of use (lazy); and
- the computation is evaluated each time it is used (not memoized).

Last but not least,
`lazy vals` are an example of call-by-need evaluation.
The code to compute `z` below
is not run until we use it
for the first time (lazy).
The result is then cached
and re-used on subsequent accesses (memoized):

```scala mdoc
lazy val z = {
  println("Computing Z")
  math.random()
}

z // first access
z // second access
```

Let's summarize. There are two properties of interest:

- evaluation at the point of definition (eager) versus at the point of use (lazy); and
- values are saved once evaluated (memoized) or not (not memoized).

There are three possible combinations of these properties:

- call-by-value which is eager and memoized;
- call-by-name which is lazy and not memoized; and
- call-by-need which is lazy and memoized.

The final combination, eager and not memoized, is not possible.


=== Eval's Models of Evaluation
fs
`Eval` has three subtypes: `Now`, `Always`, and `Later`.
They correspond to call-by-value, call-by-name, and call-by-need respectively.
We construct these with three constructor methods,
which create instances of the three classes
and return them typed as `Eval`:

```scala mdoc:silent
import cats.Eval
```

```scala mdoc
val now = Eval.now(math.random() + 1000)
val always = Eval.always(math.random() + 3000)
val later = Eval.later(math.random() + 2000)
```

We can extract the result of an `Eval`
using its `value` method:

```scala mdoc
now.value
always.value
later.value
```

Each type of `Eval` calculates its result
using one of the evaluation models defined above.
`Eval.now` captures a value _right now_.
Its semantics are similar to a `val`---eager and memoized:

```scala mdoc:invisible:reset-object
import cats.Eval
```
```scala mdoc
val x = Eval.now{
  println("Computing X")
  math.random()
}

x.value // first access
x.value // second access
```

`Eval.always` captures a lazy computation,
similar to a `def`:

```scala mdoc
val y = Eval.always{
  println("Computing Y")
  math.random()
}

y.value // first access
y.value // second access
```

Finally, `Eval.later` captures a lazy, memoized computation,
similar to a `lazy val`:

```scala mdoc
val z = Eval.later{
  println("Computing Z")
  math.random()
}

z.value // first access
z.value // second access
```


The three behaviours are summarized below.

#align(center)[
    #table(
        columns: (auto, auto, auto),
        table.header([*Scala*], [*Cats*], [*Properties*]),
        [`val`], [`Now`], [eager, memoized],
        [`def`], [`Always`], [lazy, not memoized],
        [`lazy val`], [`Later`], [lazy, memoized]
    )
]

=== Eval as a Monad


Like all monads, `Eval's` `map` and `flatMap` methods add computations to a chain.
In this case, however, the chain is stored explicitly as a list of functions.
The functions aren't run until we call
`Eval's` `value` method to request a result:

```scala mdoc
val greeting = Eval
  .always{ println("Step 1"); "Hello" }
  .map{ str => println("Step 2"); s"$str world" }

greeting.value
```

Note that, while the semantics of
the originating `Eval` instances are maintained,
mapping functions are always
called lazily on demand (`def` semantics):

```scala mdoc
val ans = for {
  a <- Eval.now{ println("Calculating A"); 40 }
  b <- Eval.always{ println("Calculating B"); 2 }
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

```scala mdoc
val saying = Eval
  .always{ println("Step 1"); "The cat" }
  .map{ str => println("Step 2"); s"$str sat on" }
  .memoize
  .map{ str => println("Step 3"); s"$str the mat" }

saying.value // first access
saying.value // second access
```

=== Trampolining and *Eval.defer*


One useful property of `Eval`
is that its `map` and `flatMap` methods are _trampolined_.
This means we can nest calls to `map` and `flatMap` arbitrarily
without consuming stack frames.
We call this property _"stack safety"_.

For example, consider this function for calculating factorials:

```scala mdoc:silent
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

```scala mdoc:invisible:reset-object
import cats.Eval
```
```scala mdoc:silent
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

```scala mdoc:invisible:reset-object
import cats.Eval
```
```scala mdoc:silent
def factorial(n: BigInt): Eval[BigInt] =
  if(n == 1) {
    Eval.now(n)
  } else {
    Eval.defer(factorial(n - 1).map(_ * n))
  }
```

```scala
factorial(50000).value
// res: A very big value
```

`Eval` is a useful tool to enforce stack safety
when working on very large computations and data structures.
However, we must bear in mind that trampolining is not free.
It avoids consuming stack by creating a chain of function objects on the heap.
There are still limits on how deeply we can nest computations,
but they are bounded by the size of the heap rather than the stack.


#exercise([Safer Folding using Eval])

The naive implementation of `foldRight` below is not stack safe.
Make it so using `Eval`:

```scala mdoc:silent
def foldRight[A, B](as: List[A], acc: B)(fn: (A, B) => B): B =
  as match {
    case head :: tail =>
      fn(head, foldRight(tail, acc)(fn))
    case Nil =>
      acc
  }
```

#solution[
The easiest way to fix this is
to introduce a helper method called `foldRightEval`.
This is essentially our original method
with every occurrence of `B` replaced with `Eval[B]`,
and a call to `Eval.defer` to protect the recursive call:

```scala mdoc:silent:reset-object
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

```scala mdoc:silent
def foldRight[A, B](as: List[A], acc: B)(fn: (A, B) => B): B =
  foldRightEval(as, Eval.now(acc)) { (a, b) =>
    b.map(fn(a, _))
  }.value
```

```scala mdoc
foldRight((1 to 100000).toList, 0L)(_ + _)
```
]
