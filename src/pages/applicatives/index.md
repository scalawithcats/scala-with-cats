# Applicatives

In previous chapters we saw how functors and monads let us transform values within a context. While these are both immensely useful abstractions, there are types of transformation that we can't represent with either `map` or `flatMap`.

One great example is form validation, where we want to accumulate errors as we go along. If we model this with a monad like `\/`, we fail fast and lose errors:

~~~ scala
def readInt(str: String): String \/ Int =
  str.parseInt.disjunction.leftMap(_ => s"Couldn't read $str")

for {
  a <- readInt("abc")
  b <- readInt("def")
  c <- readInt("ghi")
} yield (a + b + c)
// res0: scalaz.\/[List[String],Int] = -\/(List(Couldn't read abc))
~~~

To validate forms we need a more general form of combinator called an *applicative*. Monads and functors can both be modelled using applicatives, but applicatives also permit other types of combination that we haven't encountered yet.

We will start with a formal definition of applicatives, and then look in some detail at using applicatives to *combine* values in various ways. We'll then turn our attention to Scalaz' `Applicative` type class and `Validation` type.

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
