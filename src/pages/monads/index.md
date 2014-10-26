---
layout: page
title: Monads
---

*Monads* are one of the most common abstractions in Scala, and one that most Scala programmers are familiar with even if they don't know the name.

Informally, a monad is anything with a `flatMap` method. You probably know lots of types that have this: `Option`, `Seq`, `Either`, and `Future`, to name a few. We even have special syntax in Scala to support monads: for comprehensions.

Despite the ubiquity of the concept, Scala lacks a type to encompass "things that can be flatMapped". This is one of the benefits brings that Scalaz brings us when working with monads.

Let's look at the formal definition of a monad before describing the many features that Scalaz brings.

## Monad Definition

Formally, a monad for a type `F[A]` has:

- an operation `flatMap` with type `(F[A], A => B) => F[B]`
- an operation `point` with type `A => F[A]`.

We will sometimes see `bind` used in place of `flatMap`. They are the same operation, but the former is the name usually used in the academic literature. We'll use the two names interchangably.

`Point` is not an operation we're used to in Scala. It essentially abstracts over the constructor. We'll see some examples in the next section. It also goes by the name `return`.

A monad must obey three laws:

1. *Left identity*: `point(a) flatMap f == f(a)`
2. *Right identity*: `m flatMap point == m`
3. *Associativity*: `(m flatMap f) flatMap g == m flatMap (x => (f(x) flatMap g))`

## Exercises

#### Getting Funcy

A monad is also a functor. Write `map` in terms of `flatMap` and `point`.
