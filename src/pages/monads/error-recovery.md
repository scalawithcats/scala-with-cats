## Error Recovery

In the previous section we looked at modelling fail fast error handling using monads, and the `Xor` monad in particular.

In this section we're going to look at approaches for recovering from errors

### Succeeding or Choosing a Default

The `MonadPlus` type class extends `Monad` with two operations:

- `empty`, which returns an element of type `F[A]`; and
- `plus`, which accepts two elements of type `F[A]` and returns an `F[A]`.

This is the functor equivalent of a monoid.

The laws for `MonadPlus` are a bit involved, so we're going to skip them.

`MonadPlus` has syntax `<+>` which is the equivalent to `|+|`. `MonadPlus` behaves differently to `Monoid` as illustrated by these examples:

```scala
some(3) <+> some(1)
// <console>:12: error: not found: value some
//        some(3) <+> some(1)
//        ^
// <console>:12: error: not found: value some
//        some(3) <+> some(1)
//                    ^
// res27: Option[Int] = Some(3)

some(3) |+| some(1)
// <console>:14: error: not found: value some
//        some(3) |+| some(1)
//        ^
// <console>:14: error: not found: value some
//        some(3) |+| some(1)
//                    ^
// res32: Option[Int] = Some(4)

some(3) <+> none[Int]
// <console>:16: error: not found: value some
//        some(3) <+> none[Int]
//        ^
// <console>:16: error: not found: value none
//        some(3) <+> none[Int]
//                    ^
// res28: Option[Int] = Some(3)

none[Int] <+> some(3)
// <console>:18: error: not found: value none
//        none[Int] <+> some(3)
//        ^
// <console>:18: error: not found: value some
//        none[Int] <+> some(3)
//                      ^
// res29: Option[Int] = Some(3)
```

Thus `MonadPlus` allows us to provide an element that is used to recover from a failure.

(Also note `mempty`...)

### Exercise

### Folding Over Errors

It's annoying to stop a large data job because we fail on one element. Let's make `foldMapM` automatically continue when an error is encountered by the mapping function `f`. We can do this by changing the `Monad` to a `MonadPlus` and choosing a suitable value to replace the error with.

What is a suitable value?

<div class="solution">
The identity element is the obvious choice, as it won't affect the solution.
</div>

If calling `f`, the mapping function, fails use the `plus` operation to continue the computation with the value we identified above. Your code should produce a result like so:

```scala
import cats.std.anyVal._
// <console>:18: error: object anyVal is not a member of package cats.std
//        import cats.std.anyVal._
//                        ^
import cats.std.option._
// import cats.std.option._

Seq(1, 2, 3).foldMapM(a => if(a % 2 == 0) some(a) else none[Int])
// <console>:15: error: value foldMapM is not a member of Seq[Int]
//        Seq(1, 2, 3).foldMapM(a => if(a % 2 == 0) some(a) else none[Int])
//                     ^
// <console>:15: error: not found: value some
//        Seq(1, 2, 3).foldMapM(a => if(a % 2 == 0) some(a) else none[Int])
//                                                  ^
// <console>:15: error: not found: value none
//        Seq(1, 2, 3).foldMapM(a => if(a % 2 == 0) some(a) else none[Int])
//                                                               ^

// res2: Option[Int] = Some(2)
```

<div class="solution">
Here's the important part of the solution

```scala
def foldMapM[A, M[_] : MonadPlus, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
  iter.foldLeft(mzero[B].point[M]){ (accum, elt) =>
    for {
      a <- accum
      b <- f(elt) <+> mzero[B].point[M]
    } yield a |+| b
  }
// <console>:15: error: not found: type MonadPlus
//        def foldMapM[A, M[_] : MonadPlus, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
//                               ^
// <console>:15: error: not found: type Monoid
//        def foldMapM[A, M[_] : MonadPlus, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
//                                             ^
// <console>:15: error: value point is not a member of type parameter A
//        def foldMapM[A, M[_] : MonadPlus, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
//                                                                                                   ^
// <console>:15: error: not found: type Id
//        def foldMapM[A, M[_] : MonadPlus, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
//                                                                                                         ^
// <console>:16: error: not found: value mzero
//          iter.foldLeft(mzero[B].point[M]){ (accum, elt) =>
//                        ^
// <console>:15: warning: higher-kinded type should be enabled
// by making the implicit value scala.language.higherKinds visible.
// This can be achieved by adding the import clause 'import scala.language.higherKinds'
// or by setting the compiler option -language:higherKinds.
// See the Scala docs for value scala.language.higherKinds for a discussion
// why the feature should be explicitly enabled.
//        def foldMapM[A, M[_] : MonadPlus, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
//                        ^
// <console>:15: warning: higher-kinded type should be enabled
// by making the implicit value scala.language.higherKinds visible.
//        def foldMapM[A, M[_] : MonadPlus, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
//                        ^
```
</div>

What are some of the tradeoffs made by putting error handling into `foldMapM`?

<div class="solution">
By doing so, we ensure we also have error handling. However, our error handling strategy might not always be the most appropriate method, and it restricts the types of monads we can compute with. It might be better to expect the caller to provide their own error handling.
</div>

### A Toolkit for Handling Errors

It's not always appropriate for `foldMapM` to assert an error handling strategy. It's easy enough to implement custom error recovery in each function `f` we pass to `foldMap` but it would be better to build a generic toolkit. Implement a method `recover` so that you can write code like

```scala
import cats.std.anyVal._
import cats.std.option._
import cats.syntax.std.string._

Seq("1", "b", "3").foldMapM(recover(_.parseInt.toOption))
// res: Option[Int] = Some(4)
```

Hint: here's the method header for `recover`

```scala
def recover[A, M[_] : MonadPlus, B : Monoid](f: A => M[B]): (A => M[B]) = {
```

<div class="solution">
```scala
def recover[A, M[_] : MonadPlus, B : Monoid](f: A => M[B]): (A => M[B]) = {
  val identity = mzero[B].point[M]
  a => (f(a) <+> identity)
}
```
</div>

### Abstracting Over Optional Values

Cats provides another abstraction, `Optional`, that abstracts over ... err ... abstractions that may or may not hold a value. (Think `Option`, `Either`, and `Xor`). This is more restrictive than `MonadPlus` but does allow more intricate error handling.
