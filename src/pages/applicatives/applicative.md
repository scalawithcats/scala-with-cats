## *Apply* and *Applicative*

Cartesians aren't mentioned frequently
in the wider functional programming literature.
They provide a subset of the functionality of a related type class
called an *applicative functor* ("applicative" for short).
Cartesian and applicative effectively provide alternative encodings
of the notion of "zipping" values.
Applicative also provides the `pure` operation
that we've seen when discussing monads.

Cats models `Applicatives` using two type classes.
The first, `Apply`, extends `Cartesian` and `Functor` 
and adds an `ap` method that applies a parameter
to a function within a context.
The second, `Applicative` extends `Apply`,
adds the `pure` method.
Here is a simplified definition in code:

```scala
trait Apply[F[_]] extends Cartesian[F] with Functor[F] {
  def ap[A, B](ff: F[A => B])(fa: F[A]): F[B]

  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)] =
    ap(map(fa)(a => (b: B) => (a, b)))(fb)
}

trait Applicative[F[_]] extends Apply[F] {
  def pure[A](a: A): F[A]
}
```

Don't worry too much about the implementation of `product`---it's
complicated and difficult to read
and the details aren't particuarly important.
However, do notice that `product` is defined in terms of `ap` and `map`.
There is an equivalence between these three methods that
allows any one of them to be defined in terms of the other two.
The intuitive reading of this definition of `product` is as follows:

- `map` over `F[A]` to produce a value of type `F[B => (A, B)]`;
- apply `F[B]` as a parameter to `F[B => (A, B)]`
  to get a result of type `F[(A, B)]`.

By defining one of these three methods in terms of the other two,
we ensure that the definitions are consistent
for all implementations of `Apply`.
This is a pattern that we will see a lot in this section.

`Applicative` introduces the `pure` method.
This is the same `pure` we saw in `Monad`.
It constructs a new applicative instance from an unwrapped value.
In this sense, `Applicative` is related to `Apply`
as `Monoid` is related to `Semigroup`.

### The Hierarchy of Sequencing Type Classes

With the introduction of `Apply` and `Applicative`,
we can zoom out and see a a whole family of type classes
that concern themselves with sequencing computations in different ways.
We saw above that `Apply` is related to `Functor`;
`Applicative` forms the basis of `Monad`.
Here is a diagram showing the complete family:

![Monad type class hierarchy](src/pages/applicatives/hierarchy.png)

Each type class represents a particular set of sequencing semantics.
It introduces its characteristic methods,
and defines all of the functionality from its supertypes in terms of them.
Every monad is an applicative, every applicative a cartesian, and so on.

Because of the lawful nature of the relationships between the type classes,
the inheritance relationships are constant across all instances of a particular type class.
For example, `Monad` defines `product`, `ap`, and `map`, in terms of `pure` and `flatMap`:

```scala
trait Monad[F[_]] extends FlatMap[F] with Applicative[F] {
  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)] =
    flatMap(fa)(a => map(fb)(b => (a, b)))

  def ap[A, B](ff: F[A => B])(fa: F[A]): F[B] =
    flatMap(ff)(f => map(fa)(f))

  def map[A, B](fa: F[A])(f: A => B): F[B] =
    flatMap(a => pure(f(a)))
}
```

We saw a similar pattern above where `Apply` defines `product` in terms of `ap`.
This consistency gives us the ability to reason about data types in an abstract way.
To illustrate, let's consider two hypothetical data types:

- `Foo` is a monad.
  It has an instance of the `Monad` type class
  that implements `pure` and `flatMap`
  and inherits standard definitions of `product`, `map`, and `ap`;

- `Bar` is an applicative functor.
  It has an instance of `Applicative`
  that implements `pure` and `ap`
  and inherits standard definitions of `product` and `map`.

What can we say about these two data types
without knowing more about their implementations?

We know strictly more about `Foo` than `Bar`,
`Monad` is a subtype of `Applicative`,
so we can guarantee properties of `Foo` (namely `flatMap`)
that we cannot guarantee with `Bar`.
Conversely, we know that `Bar`
may have a wider range of behaviours than `Foo`.
It has fewer laws to obey (no `flatMap`),
so it can implement behaviours that `Foo` cannot.

This demonstrates the classic trade-off of power
(in the mathematical sense) versus constraints.
The more constraints we place on a data type,
the more guarantees we have about its behaviour,
but the fewer behaviours we can model.

Monads are hit a sweet spot in this trade-off.
They are flexible enough to model a wide range of behaviours
and restrictive enough to give strong guarantees about those behaviours.
However, there are situations where monads aren't the right tool for the job.
Sometimes we want thai food, and burritos just won't do the job.

Whereas monads impose a strict *sequencing* on the computations they model,
applicatives and cartesians impose no such restriction.
This puts them in another sweet spot in the hierarchy.
We can use them to represent classes parallel / independent computations
that monads cannot.
