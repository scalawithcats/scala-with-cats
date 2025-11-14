#import "../stdlib.typ": info, warning, solution, narrative-cite
== Apply and Applicative


Semigroupals aren't mentioned frequently
in the wider functional programming literature.
They provide a subset of the functionality of a related type class
called an *applicative functor* ("applicative" for short).

Cats models applicatives using two type classes.
The first, `cats.Apply`,
extends `Semigroupal` and `Functor`
and adds an `ap` method that applies a parameter
to a function within a context.
The second, `cats.Applicative`,
extends `Apply` and adds the `pure` method
introduced in @sec:monads.
Here's a simplified definition in code:

```scala
trait Apply[F[_]] extends Semigroupal[F] with Functor[F] {
  def ap[A, B](ff: F[A => B])(fa: F[A]): F[B]

  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)] =
    ap(map(fa)(a => (b: B) => (a, b)))(fb)
}

trait Applicative[F[_]] extends Apply[F] {
  def pure[A](a: A): F[A]
}
```

Breaking this down, the `ap` method applies a parameter `fa`
to a function `ff` within a context `F[_]`.
The `product` method from `Semigroupal`
is defined in terms of `ap` and `map`.

Don't worry too much about the implementation of `product`---it's
difficult to read and the details aren't particuarly important.
The main point is that there is a tight relationship
between `product`, `ap`, and `map`
that allows any one of them to be defined
in terms of the other two.

`Applicative` also introduces the `pure` method.
This is the same `pure` we saw in `Monad`.
It constructs a new applicative instance from an unwrapped value.
In this sense, `Applicative` is related to `Apply`
as `Monoid` is related to `Semigroup`.

=== The Hierarchy of Sequencing Type Classes


With the introduction of `Apply` and `Applicative`,
we can zoom out and see a whole family of type classes
that concern themselves with sequencing computations in different ways.
@fig:applicatives:hierarchy shows
the relationship between the type classes covered in this book.

#figure(
    image("hierarchy.png"),
    caption: [Monad type class hierarchy]
)<fig:applicatives:hierarchy>

Each type class in the hierarchy
represents a particular set of sequencing semantics,
introduces a set of characteristic methods,
and defines the functionality of its supertypes
in terms of them:

- every monad is an applicative;
- every applicative a semigroupal;
- and so on.

Because of the lawful nature of
the relationships between the type classes,
the inheritance relationships are constant
across all instances of a type class.
`Apply` defines `product` in terms of `ap` and `map`;
`Monad` defines `product`, `ap`, and `map`,
in terms of `pure` and `flatMap`.

To illustrate this let's consider two hypothetical data types:

- `Foo` is a monad.
  It has an instance of the `Monad` type class
  that implements `pure` and `flatMap`
  and inherits standard definitions of `product`, `map`, and `ap`;

- `Bar` is an applicative functor.
  It has an instance of `Applicative`
  that implements `pure` and `ap`
  and inherits standard definitions of `product` and `map`.

What can we say about these two data types
without knowing more about their implementation?

We know strictly more about `Foo` than `Bar`:
`Monad` is a subtype of `Applicative`,
so we can guarantee properties of `Foo` (namely `flatMap`)
that we cannot guarantee with `Bar`.
Conversely, we know that `Bar`
may have a wider range of behaviours than `Foo`.
It has fewer laws to obey (no `flatMap`),
so it can implement behaviours that `Foo` cannot.

This demonstrates the classic trade-off of power
(in the mathematical sense) versus constraint.
The more constraints we place on a data type,
the more guarantees we have about its behaviour,
but the fewer behaviours we can model.

Monads happen to be a sweet spot in this trade-off.
They are flexible enough to model a wide range of behaviours
and restrictive enough to give strong guarantees about those behaviours.
However, there are situations where monads
aren't the right tool for the job.
Sometimes we want Thai food,
and burritos just won't satisfy.

Whereas monads impose a strict _sequencing_
on the computations they model,
applicatives and semigroupals impose no such restriction.
This puts them in a different sweet spot in the hierarchy.
We can use them to represent
classes of independent computations
that monads cannot.

We choose our semantics by choosing our data structures.
If we choose a monad, we get strict sequencing.
If we choose an applicative, we lose the ability to `flatMap`.
This is the trade-off enforced by the consistency laws.
So choose your types carefully!
