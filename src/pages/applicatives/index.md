# Applicatives

In previous chapters we saw how monads and monad transformers help us *sequence* computations. In this chapter we will *applicatives*, which allow us to *apply functions to values within a context* such as `Option` or `\/`. Perhaps the most common use of applicatives is to *combine values*, which we will discuss in detail this chapter.

You might reasonably ask: what is the difference between sequencing computations and applying functions? After all, you could argue that a for comprehension is transforming the values from each of its clauses:

~~~ scala
for {
  a <- Some(1)
  b <- Some(2)
  c <- Some(3)
} yield (a + b + c)
~~~

If you remember from the section on the [`Monad` type class](#monad-type-class), `Monad` is a subtype of `Applicative`. This means all `Monads` are `Applicatives` but not all `Applicatives` are `Monads`. Monadic comprehension is *one* way of transforming the results of computations, but it is not the *only* way---applicatives allow more flexibility than monads.

## Definition of an Applicative

Formally, an applicative for a type `F[A]` has:

 - an operation `ap` with type `(F[A], F[A => B]) => F[B]`;
 - an operation `point` with type `A => F[A]` (sometimes called `pure`).

The `point` operation here is the same as `point` for a monad. However, `ap` is subtly different from `bind`. Instead of accepting a function parameter of type `A => F[B]`, it accepts a parameter of type `F[A => B]`:

~~~ scala
def ap[F[_], A, B](value: => F[A])(func: => F[A => B]): F[B] = ???

def bind[F[_], A, B](value: => F[A])(func: A => F[B]): F[B] = ???
~~~

The intuitive difference here is that monads are *context sensitive* while applicatives are *context free*. The `func` parameter of a monad gets to choose what type of `F` to return, whereas the `func` of an applicative is called after the `F` has been determined. This ties in naturally with the concept of sequencing in a monad where each stage determines the next.

The `func` parameter of `ap` is *context free*---it is a functor-like mapping from `A` to `B`. The definition of `ap` can decide how and whether to combine `value` and `func`, but the user code can't control the construction of instance of `F`.

The rules for an applicative are as follows:

 - *Identity*: `ap(a)(point(x => x)) == a`
 - *Homomorphism*: `ap(point(a))(point(b)) == point(b(a))`
 - *Interchange*: `ap(point(a))(fb) == ap(fb)(point(x => x(a)))`
 - *Map-like*: `map(fa)(fb) == ap(fa)(point(fb))`

At this point you may be confused. Let's ground this with a concrete example to demonstrate the various ways we can implement an applicative.
