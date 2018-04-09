# Monads {#sec:monads}

*Monads* are one of the most common abstractions in Scala.
Many Scala programmers quickly become intuitively familiar with monads,
even if we don't know them by name.

Informally, a monad is anything with a constructor and a `flatMap` method.
All of the functors we saw in the last chapter are also monads,
including `Option`, `List`, and `Future`.
We even have special syntax to support monads: for comprehensions.
However, despite the ubiquity of the concept,
the Scala standard library lacks
a concrete type to encompass "things that can be `flatMapped`".
This type class is one of the benefits brought to us by Cats.

In this chapter we will take a deep dive into monads.
We will start by motivating them with a few examples.
We'll proceed to their formal definition and their implementation in Cats.
Finally, we'll tour some interesting monads that you may not have seen,
providing introductions and examples of their use.

## What is a Monad?

This is the question that has been posed in a thousand blog posts,
with explanations and analogies involving concepts as diverse as
cats, Mexican food, space suits full of toxic waste,
and monoids in the category of endofunctors (whatever that means).
We're going to solve the problem of explaining monads once and for all
by stating very simply:

> A monad is a mechanism for *sequencing computations*.

That was easy! Problem solved, right?
But then again, last chapter we said functors
were a control mechanism for exactly the same thing.
Ok, maybe we need some more discussion...

In Section [@sec:functors:examples]
we said that functors allow us
to sequence computations ignoring some complication.
However, functors are limited in that
they only allow this complication
to occur once at the beginning of the sequence.
They don't account further complications
at each step in the sequence.

This is where monads come in.
A monad's `flatMap` method allows us to specify what happens next,
taking into account an intermediate complication.
The `flatMap` method of `Option` takes intermediate `Options` into account.
The `flatMap` method of `List` handles intermediate `Lists`. And so on.
In each case, the function passed to `flatMap` specifies
the application-specific part of the computation,
and `flatMap` itself takes care of the complication
allowing us to `flatMap` again.
Let's ground things by looking at some examples.

**Options**

`Option` allows us to sequence computations
that may or may not return values.
Here are some examples:

```tut:book:silent
def parseInt(str: String): Option[Int] =
  scala.util.Try(str.toInt).toOption

def divide(a: Int, b: Int): Option[Int] =
  if(b == 0) None else Some(a / b)
```

Each of these methods may "fail" by returning `None`.
The `flatMap` method allows us to ignore this
when we sequence operations:

```tut:book:silent
def stringDivideBy(aStr: String, bStr: String): Option[Int] =
  parseInt(aStr).flatMap { aNum =>
    parseInt(bStr).flatMap { bNum =>
      divide(aNum, bNum)
    }
  }
```

We know the semantics well:

- the first call to `parseInt` returns a `None` or a `Some`;
- if it returns a `Some`, the `flatMap` method calls our function and passes us the integer `aNum`;
- the second call to `parseInt` returns a `None` or a `Some`;
- if it returns a `Some`, the `flatMap` method calls our function and passes us `bNum`;
- the call to `divide` returns a `None` or a `Some`, which is our result.

At each step, `flatMap` chooses whether to call our function,
and our function generates the next computation in the sequence.
This is shown in Figure [@fig:monads:option-type-chart].

![Type chart: flatMap for Option](src/pages/monads/option-flatmap.pdf+svg){#fig:monads:option-type-chart}

The result of the computation is an `Option`,
allowing us to call `flatMap` again and so the sequence continues.
This results in the fail-fast error handling behaviour that we know and love,
where a `None` at any step results in a `None` overall:

```tut:book
stringDivideBy("6", "2")
stringDivideBy("6", "0")
stringDivideBy("6", "foo")
stringDivideBy("bar", "2")
```

Every monad is also a functor (see below for proof),
so we can rely on both `flatMap` and `map`
to sequence computations
that do and don't introduce a new monad.
Plus, if we have both `flatMap` and `map`
we can use for comprehensions
to clarify the sequencing behaviour:

```tut:book:silent
def stringDivideBy(aStr: String, bStr: String): Option[Int] =
  for {
    aNum <- parseInt(aStr)
    bNum <- parseInt(bStr)
    ans  <- divide(aNum, bNum)
  } yield ans
```

**Lists**

When we first encounter `flatMap` as budding Scala developers,
we tend to think of it as a pattern for iterating over `Lists`.
This is reinforced by the syntax of for comprehensions,
which look very much like imperative for loops:

```tut:book
for {
  x <- (1 to 3).toList
  y <- (4 to 5).toList
} yield (x, y)
```

However, there is another mental model we can apply
that highlights the monadic behaviour of `List`.
If we think of `Lists` as sets of intermediate results,
`flatMap` becomes a construct that calculates
permutations and combinations.

For example, in the for comprehension above
there are three possible values of `x` and two possible values of `y`.
This means there are six possible values of `(x, y)`.
`flatMap` is generating these combinations from our code,
which states the sequence of operations:

- get `x`
- get `y`
- create a tuple `(x, y)`

<!--
The type chart in Figure [@fig:monads:list-type-chart]
illustrates this behaviour[^list-lengths].

![Type chart: flatMap for List](src/pages/monads/list-flatmap.pdf+svg){#fig:monads:list-type-chart}

[^list-lengths]: Although the result of `flatMap` (`List[B]`)
is the same type as the result of the user-supplied function,
the end result is actually a larger list
created from combinations of intermediate `As` and `Bs`.
-->

**Futures**

`Future` is a monad that sequences computations
without worrying that they are asynchronous:

```tut:book:silent
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

def doSomethingLongRunning: Future[Int] = ???
def doSomethingElseLongRunning: Future[Int] = ???

def doSomethingVeryLongRunning: Future[Int] =
  for {
    result1 <- doSomethingLongRunning
    result2 <- doSomethingElseLongRunning
  } yield result1 + result2
```

Again, we specify the code to run at each step,
and `flatMap` takes care of all the horrifying
underlying complexities of thread pools and schedulers.

If you've made extensive use of `Future`,
you'll know that the code above
is running each operation *in sequence*.
This becomes clearer if we expand out the for comprehension
to show the nested calls to `flatMap`:

```tut:book:silent
def doSomethingVeryLongRunning: Future[Int] =
  doSomethingLongRunning.flatMap { result1 =>
    doSomethingElseLongRunning.map { result2 =>
      result1 + result2
    }
  }
```

Each `Future` in our sequence is created
by a function that receives the result from a previous `Future`.
In other words, each step in our computation can only start
once the previous step is finished.
This is born out by the type chart for `flatMap`
in Figure [@fig:monads:future-type-chart],
which shows the function parameter of type `A => Future[B]`.

![Type chart: flatMap for Future](src/pages/monads/future-flatmap.pdf+svg){#fig:monads:future-type-chart}

We *can* run futures in parallel, of course,
but that is another story and shall be told another time.
Monads are all about sequencing.

### Definition of a Monad

While we have only talked about `flatMap` above,
monadic behaviour is formally captured in two operations:

- `pure`, of type `A => F[A]`;
- `flatMap`[^bind], of type `(F[A], A => F[B]) => F[B]`.

[^bind]: In some libraries and languages,
notably Scalaz and Haskell,
`pure` is referred to as `point` or `return` and
`flatMap` is referred to as `bind` or `>>=`.
This is purely a difference in terminology.
We'll use the term `flatMap` for compatibility
with Cats and the Scala standard library.

`pure` abstracts over constructors,
providing a way to create a new monadic context from a plain value.
`flatMap` provides the sequencing step we have already discussed,
extracting the value from a context and generating
the next context in the sequence.
Here is a simplified version of the `Monad` type class in Cats:

```tut:book:silent
import scala.language.higherKinds

trait Monad[F[_]] {
  def pure[A](value: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]
}
```

<div class="callout callout-warning">
*Monad Laws*

`pure` and `flatMap` must obey a set of laws
that allow us to sequence operations freely
without unintended glitches and side-effects:

*Left identity*: calling `pure`
and transforming the result with `func`
is the same as calling `func`:

```scala
pure(a).flatMap(func) == func(a)
```

*Right identity*: passing `pure` to `flatMap`
is the same as doing nothing:

```scala
m.flatMap(pure) == m
```

*Associativity*: `flatMapping` over two functions `f` and `g`
is the same as `flatMapping` over `f` and then `flatMapping` over `g`:

```scala
m.flatMap(f).flatMap(g) == m.flatMap(x => f(x).flatMap(g))
```
</div>

### Exercise: Getting Func-y

Every monad is also a functor.
We can define `map` in the same way for every monad
using the existing methods, `flatMap` and `pure`:

```tut:book:silent
import scala.language.higherKinds

trait Monad[F[_]] {
  def pure[A](a: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]

  def map[A, B](value: F[A])(func: A => B): F[B] =
    ???
}
```

Try defining `map` yourself now.

<div class="solution">
At first glance this seems tricky,
but if we follow the types we'll see there's only one solution.
We are passed a `value` of type `F[A]`.
Given the tools available there's only one thing we can do:
call `flatMap`:

```tut:book:silent
trait Monad[F[_]] {
  def pure[A](value: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]

  def map[A, B](value: F[A])(func: A => B): F[B] =
    flatMap(value)(a => ???)
}
```

We need a function of type `A => F[B]` as the second parameter.
We have two function building blocks available:
the `func` parameter of type `A => B`
and the `pure` function of type `A => F[A]`.
Combining these gives us our result:

```tut:book:silent
trait Monad[F[_]] {
  def pure[A](value: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]

  def map[A, B](value: F[A])(func: A => B): F[B] =
    flatMap(value)(a => pure(func(a)))
}
```
</div>
