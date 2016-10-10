# Monads

*Monads* are one of the most common abstractions in Scala
and one that most Scala programmers are familiar with
even if they don't know the name.

Informally, a monad is anything with a `flatMap` method.
All of the functors we saw in the last chapter are also monads,
including `Option`, `Seq`, `Either`, and `Future`.
We even have special syntax in Scala to support monads:
for comprehensions.

Despite the ubiquity of the concept,
Scala lacks a concrete type to encompass "things that can be flatMapped".
This is one of the benefits that Cats brings us.

We will start by looking at the motivation for monads.
We'll proceed to look at at their formal definition,
and finally to their implementation in Cats.

## What is a Monad?

This is the question that has been posed in a thousand blog posts
involving concepts as diverse as cats, burritos, 
and monoids in the category of endofunctors (whatever they are).
We're going to solve this problem once and for all by stating very simply:
a monad is a control mechanism for *sequencing computations*.

Informally, the most important feature of a monad is its `flatMap` method,
which allows users to sequence a computation.
The user provides the application-specific parts of the computation
as a function parameter, 
and the `flatMap` method itself takes care of some complication.
Let's ground this by looking at some examples.

**Option**

`Option` is a monad that handles the complication
that some operations in a program may or may not be able to return values.
Here are some example operations:

```tut:book:silent
def parseInt(str: String): Option[Int] =
  scala.util.Try(str.toInt).toOption

def divide(a: Int, b: Int): Option[Int] =
  if(b == 0) None else Some(a / b)
```

The `flatMap` method on `Option` allows us to sequence operations such as these
without having to constantly check whether they return `Some` or `None`:

```tut:book
def stringDivideBy(aStr: String, bStr: String): Option[Int] =
  parseInt(aStr).flatMap { aNum => 
    parseInt(bStr).flatMap { bNum => 
      divide(aNum, bNum)
    }
  }
```

At each step, the user-supplied function to `flatMap` 
generates the next `Option` for the next step:

![Type chart: flatMap for Option](src/pages/monads/option-flatmap.pdf+svg)

This results in a fail-fast error handling behaviour
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
that do and and don't introduce a new monad.
Plus, if we have both `flatMap` and `map`
we can use for comprehensions
to clarify the sequencing behaviour:

```tut:book
def stringDivideBy(aStr: String, bStr: String): Option[Int] =
  for {
    aNum <- parseInt(aStr)
    bNum <- parseInt(bStr)
    ans  <- divide(aNum, bNum)
  } yield ans
```

**List**

We can think of functions that return `Lists`
as returning a variable number of results:

```tut:book:silent
def numbersBetween(min: Int, max: Int): List[Int] =
  (min to max).toList

def pairs(a: Int, b: Int): List[(Int, Int)] =
  List((a, b), (b, a))
```

The `flatMap` method on `List` allows us to calculate
permutations and combinations of intermediate results:

```tut:book
for {
  a <- numbersBetween(1, 2)
  b <- numbersBetween(3, 4)
  p <- pairs(a, b)
} yield p
```

At each step, the user-supplied function 
generates a list of possible results.
The `flatMap` method calls the function 
with every input accumulated so far,
generating result for every combination of input and output:

![Type chart: flatMap for List](src/pages/monads/list-flatmap.pdf+svg)

**Futures**

`Future` is a monad that allows us to sequence computations
without worrying about the fact they are asynchronous:

```tut:book:silent
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

def getTrafficFromHost(hostname: String): Future[Int] =
  ???

def getTrafficFromAllHosts: Future[Int] =
  for {
    traffic1 <- getTrafficFromHost("host1")
    traffic2 <- getTrafficFromHost("host2")
  } yield traffic1 + traffic2
```

Again, the `flatMap` method allows us to specify 
the application-specific parts of the behaviour.
It takes care all of the complexities of scheduling,
threads, and thread pools internally:

![Type chart: flatMap for Future](src/pages/monads/future-flatmap.pdf+svg)

### Monad Definition and Laws

While we have only talked about the `flatMap` method above,
The monad behaviour is formally captured in two operations:

- an operation `pure` with type `A => F[A]`;
- an operation `flatMap`[^bind] with type `(F[A], A => F[B]) => F[B]`.

The `pure` operation abstracts over the constructor,
providing a way to create a new monad from a value.

Here is a simple Scala definition of a `Monad` type class:

```tut:book:silent
import scala.language.higherKinds

trait Monad[F[_]] {
  def pure[A](value: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]
}
```

The `pure` and `flatMap` methods must obey three laws:

*Left identity*: calling `pure` 
then transforming the result with a function `f`
is the same as simply calling `f`:

```scala
pure(a).flatMap(f) == f(a)
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

These laws guarantee that our `pure` and `flatMap` methods
behave simply and consistently.
They allow us to write generic code that works with any monad,
regardless of what complication(s) it eliminates from our code.

### Exercise: Getting Func-y

Every monad is also a functor.
If `flatMap` represents sequencing a computation 
that introduces a new monadic context,
`map` represents sequencing a computation that does not.
We can define `map` in the same way for every monad
using the existing methods, `flatMap` and `pure`:

```tut:book:silent
import scala.language.higherKinds

trait Monad[F[_]] {
  def pure[A](a: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]
}
```

Try defining `map` yourself now.

<div class="solution">
At first glance this seems tricky,
but if we follow the types we'll see there's only one solution.
Let's start by writing the method header:

```tut:book:silent
trait Monad[F[_]] {
  def pure[A](value: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]

  def map[A, B](value: F[A])(func: A => B): F[B] =
    ???
}
```

Now we look at the types. 
We've been given a `value` of type `F[A]`.
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
