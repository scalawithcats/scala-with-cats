# Monads

*Monads* are one of the most common abstractions in Scala, and one that most Scala programmers are familiar with even if they don't know the name.

Informally, a monad is anything with a `flatMap` method. You probably know lots of types that have this: `Option`, `Seq`, `Either`, and `Future`, to name a few. We even have special syntax in Scala to support monads: for comprehensions.

Despite the ubiquity of the concept, Scala lacks a type to encompass "things that can be flatMapped". This is one of the benefits that Scalaz brings us.

As usual, we will start looking at the formal definition of a monad, and then proceed to its implementation in Scalaz.

## Definition of a Monad

Formally, a monad for a type `F[A]` has:

- an operation `flatMap` with type `(F[A], A => B) => F[B]`
- an operation `point` with type `A => F[A]`.

We will sometimes see the name `bind` used in place of `flatMap`. These are the same operation, but the former is the name usually used in the academic literature. We'll use the two names interchangably.

`point` is not an operation we're used to in Scala. It essentially abstracts over the constructor. We'll see some examples of this in the next section. `point` also goes by the name `return`.

A monad must obey three laws:

1. *Left identity*: `(point(a) flatMap f) == f(a)`
2. *Right identity*: `(m flatMap point) == m`
3. *Associativity*: `((m flatMap f) flatMap g) == (m flatMap (x => (f(x) flatMap g)))`

## Exercise: Getting Func-y

A monad is also a functor. Write `map` in terms of the following definitions of `flatMap` and `point`:

~~~ scala
def flatMap[F[_], A, B](value: F[A])(func: A => F[B]): F[B] = ???

def point[F[_], A](value: A): F[A] = ???
~~~

<div class="solution">
At first glance this seems tricky, but if we follow the types we'll see there's only one solution. Let's start by writing the method header:

~~~ scala
def map[F[_], A, B](value: F[A])(func: A => B): F[B] =
  ???
~~~

Now we look at the types. We've been given a `value` of type `F[A]`. Given the tools available, there's only one thing we can do here---call `flatMap`:

~~~ scala
def map[F[_], A, B](value: F[A])(func: A => B): F[B] =
  flatMap(value)(???)
~~~

We need a function of type `A => F[B]` as the second parameter. We have two function building blocks available: the `func` parameter of type `A => B` and the `point` function of type `A => F[A]`. Combining these gives us our result:

~~~ scala
def map[F[_], A, B](value: F[A])(func: A => B): F[B] =
  flatMap(value)(a => point(func(a)))
~~~
</div>
