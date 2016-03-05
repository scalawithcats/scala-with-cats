# Monads

*Monads* are one of the most common abstractions in Scala, and one that most Scala programmers are familiar with even if they don't know the name.

Informally, a monad is anything with a `flatMap` method. All of the functors we saw in the last chapter are also monads, including `Option`, `Seq`, `Either`, and `Future`. We even have special syntax in Scala to support monads: for comprehensions.

Despite the ubiquity of the concept, Scala lacks a concrete type to encompass "things that can be flatMapped". This is one of the benefits that Cats brings us.

As usual, we will start looking at the formal definition of a monad, and then proceed to its implementation in Cats.

## Definition of a Monad

Formally, a monad for a type `F[A]` has:

- an operation `flatMap` with type `(F[A], A => F[B]) => F[B]`
- an operation `pure` with type `A => F[A]`.

You will sometimes hear people refer to the "flatMap" operation as "bind". This is the name used in Haskell and academic literature. Cats consistently refers to the operation as `flatMap`, and we will continue to do so here.

`pure` abstracts over the constructor of our monad. We'll see some examples of this in the next section. The academic name for this operation is "return", but we'll be sticking to "pure".

A monad must obey three laws:

1. *Left identity*: `(pure(a) flatMap f) == f(a)`
2. *Right identity*: `(m flatMap pure) == m`
3. *Associativity*: `(m flatMap f flatMap g) == (m flatMap (x => f(x) flatMap g))`

## Exercise: Getting Func-y

A monad is also a functor. Write `map` in terms of the following definitions of `flatMap` and `pure`:

```scala
import scala.language.higherKinds

def flatMap[F[_], A, B](value: F[A])(func: A => F[B]): F[B] = ???

def pure[F[_], A](value: A): F[A] = ???
```

<div class="solution">
At first glance this seems tricky, but if we follow the types we'll see there's only one solution. Let's start by writing the method header:

```scala
def map[F[_], A, B](value: F[A])(func: A => B): F[B] = ???
```

Now we look at the types. We've been given a `value` of type `F[A]`. Given the tools available, there's only one thing we can do here---call `flatMap`:

```scala
def map[F[_], A, B](value: F[A])(func: A => B): F[B] =
  flatMap(value)(???)
```

We need a function of type `A => F[B]` as the second parameter. We have two function building blocks available: the `func` parameter of type `A => B` and the `pure` function of type `A => F[A]`. Combining these gives us our result:

```scala
def map[F[_], A, B](value: F[A])(func: A => B): F[B] =
  flatMap(value)(a => pure(func(a)))
```
</div>
