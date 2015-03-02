# Applicatives

In previous chapters we saw how monads and monad transformers help us *sequence* computations. We're missing a tool that lets take independent computations and *join* them to produce a result. This tool, called an *applicative*, is the subject of this chapter.

Applicatives are one of the harder functional paradigms to explain. We'll start with a formal definition and then move into a lengthy worked example before discussing the definition of `Applicative` in Scalaz. We'll finish this chapter with a discussion of `Validation`, the most common Scalaz data type to make use of applicatives.

## Definition of an Applicative

Formally, an applicative for a type `F[A]` has:

 - an operation `ap` with type `(F[A], F[A => B]) => F[B]`;
 - an operation `point` with type `A => F[A]` (sometimes called `pure`).

The `point` operation here is the same as `point` for a monad. However, `ap` is subtly different from `bind`. Instead of accepting a function parameter of type `A => F[B]`, it accepts a parameter of type `F[A => B]`:

~~~ scala
def ap[F[_], A, B](value: F[A])(func: F[A => B]): F[B] = ???

def bind[F[_], A, B](value: F[A])(func: A => F[B]): F[B] = ???
~~~

The intuitive difference here is that monads are *context sensitive* while applicatives are *context free*. The `func` parameter of a monad gets to choose what type of `F` to return, whereas the `func` of an applicative is called after the `F` has been determined. This ties in naturally with the concept of sequencing in a monad where each stage determines the next, versus joining in an applicative where the stages are complete by the time we start joining values.

Applicatives are a *weaker* concept than monads. We can define an applicative for every monad, but not every applicative is a monad.

The rules for an applicative are as follows:

 - *Identity*: `ap(a)(point(x => x)) == a`
 - *Homomorphism*: `ap(point(a))(point(b)) == point(b(a))`
 - *Interchange*: `ap(point(a))(fb) == ap(fb)(point(x => x(a)))`
 - *Map-like*: `map(fa)(fb) == ap(fa)(point(fb))`

At this point you're probably pretty confused. Let's ground this with a concrete example.
