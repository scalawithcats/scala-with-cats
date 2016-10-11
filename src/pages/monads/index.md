# Monads

*Monads* are one of the most common abstractions in Scala.
Many Scala programmers quickly become intuitively familiar with monads,
even if we don't know them by name.

Informally, a monad is anything with a `flatMap` method.
All of the functors we saw in the last chapter are also monads,
including `Option`, `Seq`, `Either`, and `Future`.
We even have special syntax to support monads: for comprehensions.
However, despite the ubiquity of the concept,
Scala lacks a concrete type to encompass "things that can be flatMapped".
This is one of the benefits that Cats brings us.

In this chapter we will take a deep dive into monads.
We will start by motivating them with a few examples.
We'll proceed to their formal definition and their implementation in Cats.
Finally, we'll tour some interesting monads that you may not have heard of,
providing introductions and examples of their use.

## What is a Monad?

This is the question that has been posed in a thousand blog posts,
with explanations and analogies involving concepts as diverse as cats, mexican food, 
and monoids in the category of endofunctors (whatever they are).
We're going to solve the problem of explaining monads once and for all by stating very simply:

> A monad is a control mechanism for *sequencing computations*.

That was easy! Problem solved, right? Ok, maybe we need some more discussion...

Informally, the most important feature of a monad is its `flatMap` method,
which allows us specify what happens next in the sequence.
We specify the application-specific part of the computation as a function parameter, 
and `flatMap` runs our function and takes care of some kind of complication
(conventionally referred to as an ``effect'').
Let's ground things by looking at some examples.

**Options**

`Option` is a monad that allows us to sequence computations
that may or may not to return values.
Here are some examples:

```tut:book:silent
def parseInt(str: String): Option[Int] =
  scala.util.Try(str.toInt).toOption

def divide(a: Int, b: Int): Option[Int] =
  if(b == 0) None else Some(a / b)
```

Each of these computations may fail, as indicated by their `Option` return types.
The `flatMap` method on `Option` allows us to sequence these operations
without having to constantly check whether they return `Some` or `None`:

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
- if it returns a `Some`, the `flatMap` method calls our function and passes us `aNum`;
- the second call to `parseInt` returns a `None` or a `Some`;
- if it returns a `Some`, the `flatMap` method calls our function and passes us `bNum`;
- the call to `divide` returns a `None` or a `Some`, which is our result.

At each step, `flatMap` chooses whether to call our function.
and our function generates the next computation in the sequence:

![Type chart: flatMap for Option](src/pages/monads/option-flatmap.pdf+svg)

The result of computation is an `Option`, 
allowing us to call `flatMap` again and so the process continues.
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
that do and and don't introduce a new monad.
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

```tut:book:silent
def numbersBetween(min: Int, max: Int): List[Int] =
  (min to max).toList
```

```tut:book
for {
  x <- numbersBetween(1, 3)
  y <- numbersBetween(4, 5)
} yield (x, y)
```

However, there is another mental model we can apply
that highlights the monadic behaviour of `List`.
If we think of functions that return `Lists`
as functions with multiple return values,
`flatMap` becomes a construct that calculates 
results from permutations and combinations of intermediate values.

For example, in the for comprehension above, 
there are three possible values of `x` and two possible values of `y`.
This means there are six possible values of the overall expression.
`flatMap` is generating these combinations from our code, 
which simply says "get x from here and y from over there".

The type chart below illustrates this behaviour:
although the result of `flatMap` (`List[B]`) 
is the same type as the result of the user-supplied function,
the end result is actually a larger list
created from combinations of intermediate `As` and `Bs`:

![Type chart: flatMap for List](src/pages/monads/list-flatmap.pdf+svg)

**Futures**

`Future` is a monad that allows us to sequence computations
without worrying that they are asynchronous:

```tut:book:silent
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

def getTrafficFromHost(hostname: String): Future[Int] =
  ??? // grab traffic information using a network client

def getTrafficFromAllHosts: Future[Int] =
  for {
    traffic1 <- getTrafficFromHost("host1")
    traffic2 <- getTrafficFromHost("host2")
    traffic3 <- getTrafficFromHost("host3")
  } yield traffic1 + traffic2 + traffic3
```

Again, we specify the code to run at each step,
and `flatMap` takes care of all the horrifying
underlying complexities of thread pools and schedulers.

If you've made extensive use of Scala's `Futures`,
you'll know that the code above 
is fetching traffic from each server *in sequence*.
This becomes clearer if we expand out the for comprehension
to show the nested calls to `flatMap`:

```tut:book:silent
def getTrafficFromAllHosts: Future[Int] =
  getTrafficFromHost("host1").flatMap { traffic1 =>
    getTrafficFromHost("host2").flatMap { traffic2 =>
      getTrafficFromHost("host3").map { traffic3 =>
        traffic1 + traffic2 + traffic3
      }
    }
  }
```

Each `Future` in our sequence is created 
by a function that receives the result from a previous `Future`.
In other words, each step in our computation can only start
once the previous step is finished.
This is born out by the type chart for `flatMap`,
which shows the function parameter of type `A => Future[B]`:

![Type chart: flatMap for Future](src/pages/monads/future-flatmap.pdf+svg)

In other words, the monadic behaviour of `Future`
allows us to sequence asynchronous computations one after the other.
We can run `Futures` in parallel, but that's a different topic of conversation.
Monads are truly all about sequencing.

### Monad Definition and Laws

While we have only talked about the `flatMap` method above,
The monad behaviour is formally captured in two operations:

- an operation `pure` with type `A => F[A]`;
- an operation `flatMap`[^bind] with type `(F[A], A => F[B]) => F[B]`.

[^bind]: In some languages and libraries,
notably Haskell and Scalaz, `flatMap` is referred to as `bind`.
This is purely a difference in terminology.
We'll use the term `flatMap` 
for compatibility with Cats and the Scala standard library.

The `pure` operation abstracts over constructors,
providing a way to create a new monadic context from a plain value.
`flatMap` provides the sequencing step we have already discussed,
extracting the value from a context and using the supplied function
to generate the next context in the sequence.
Here is a simplified version of the `Monad` type class in Cats:

```tut:book:silent
import scala.language.higherKinds

trait Monad[F[_]] {
  def pure[A](value: A): F[A]

  def flatMap[A, B](value: F[A])(func: A => F[B]): F[B]
}
```

Importantly, the `pure` and `flatMap` methods must obey three laws:

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
