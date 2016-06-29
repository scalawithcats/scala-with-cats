-----

Mention this at the beginning of the `Applicative` section:

- "Monads and functors can both be modelled using these type classes, but applicatives and cartesians also permit other types of combination that we haven't encountered yet."

-----

## Intuitive Definition of an Applicative

Applicative functors are similar to functors---they allow us to apply functions to values within a context. However, applicative functors have more than one contextual input---they are used to *combine* values together. This is useful for modelling parallel operations that run independently but produce combinable results. Formally, we can describe an applicative for a type `F[_]` as follows:

```scala
trait Applicative[F[_]] {
  def point[A](value: A): F[A]

  def apply2[A, B, C](a: F[A], b: F[B])
        (func: (A, B) => C): F[C]
}
```

Unlike monads, applicatives are *context free*---the `func` argument to `apply2` has no control over the shape of `F[C]`---the body of `apply2` has complete control over the construction of the result.

Let's see an example. Many monads are also applicatives---we can see how things work by looking at `Option`:

```scala
import cats.Applicative
// import cats.Applicative

import cats.instances.option._
// import cats.instances.option._

val optApp = Applicative[Option]
// optApp: cats.Applicative[Option] = cats.instances.OptionInstances$$anon$1@650c649e

optApp.apply2(
  some("hello"),
  some("applicatives")
) { (a, b) => (a, b) }
// <console>:17: error: value apply2 is not a member of cats.Applicative[Option]
//        optApp.apply2(
//               ^
// <console>:18: error: not found: value some
//          some("hello"),
//          ^
// <console>:19: error: not found: value some
//          some("applicatives")
//          ^
```

## Combining Three or More Values

You may be wondering: if an applicative can be used to combine two values, what about three values or more? There are two answers to this: one that is conceptual and one that is specific to Cats.

The conceptual answer is that we can use an applicative to combine any number of inputs. We can define methods `apply3`, `apply4`, and so on for arbitrary numbers of arguments, all in terms of the same underlying code.

The Cats-specific answer is that there are implementations of `applyN` for up to 12 arguments (ignoring `func`). Scala is bad at abstracting over arity as we know from the 22-limit on functions and tuples. The Cats developers didn't see the point in going all the way to 22---they decided to stop 10 short of the usual limit:

```scala
optApp.apply3(
// <console>:5: error: ')' expected but '.' found.
// optApp.apply3(
//       ^
  some("applicatives"),
  some("totally"),
  some("rock")
) { (a, b, c) =>
  s"$a $b $c"
}
// <console>:17: error: value apply2 is not a member of cats.Applicative[Option]
//        optApp.apply2(
//               ^
// <console>:18: error: not found: value some
//          some("hello"),
//          ^
// <console>:19: error: not found: value some
//          some("applicatives")
//          ^
// <console>:21: error: not found: value some
//          some("totally"),
//          ^
// <console>:22: error: not found: value some
//          some("rock")
//          ^
```

## Actual Definition of an Applicative

What we've seen so far is an *intuitive* definition of applicatives, but it's not the *underlying* definition in Cats. We encourage you to think of applicatives in terms of `applyN` as described above---what follows is included for completeness but is a difficult implementation to grasp.

Applicatives in Cats are *actually* defined in terms of an underlying method called `ap`:

```scala
trait Applicative[F[_]] {
  def point[A](value: A): F[A]

  def ap[A, B](a: F[A])(func: F[A => B]): F[B]
}
```

We can derive each of our `applyN` methods above in terms of `ap`. Here are examples for `apply2` and `apply3`:

```scala
def apply2[A, B, C](a: F[A], b: F[B])
      (func: (A, B) => C): F[C] =
  ap(b)(ap(a)(func.curried))

def apply2[A, B, C, D](a: F[A], b: F[B], c: F[C])
      (func: (A, B, C) => D): F[D] =
  ap(c)(ap(b)(ap(a)(func.curried)))
```

To understand this code we first need to understand *currying*,  the process of turning a multi-argument function into a series of nested unary functions. Here's an example:

```scala
val addNumbers =
  (a: Int, b: Int, c: Int) => a + b + c

addNumbers(1, 2, 3)

val addCurried =
  (a: Int) => (b: Int) => (c: Int) => a + b + c

addCurried(1)(2)(3)
```

In this code, `addNumbers` is a function that accepts three parameters and sums them. `addCurried` is the curried equivalent of `addNumbers`---it is a series of three nested functions, each of which accepts one of the parameters and returns the next. When all three parameters have been supplied, the final function in the chain returns the result of the addition.

Curried and uncurried functions are essentially different ways of writing equivalent code. In Haskell, for example, all functions have one argument and all multi-argument functions are represented via currying. In Scala, every `Function` object of two or more arguments has a `curried` method that converts it to curried form. The `addCurried` example above can be re-written as follows:

```scala
val addCurried = addNumbers.curried

addCurried(1)(2)(3)
```

Now we understand currying, let's take another look at the at the definition of `apply2` above. Here's how the code works:

1. it curries `func` and wraps it using `point`, providing a value of `F[A => B => C]`;
2. it passes `a` and the curried `func` to `ap`, returning a value of type `F[B => C]`;
3. it passes `b` and the result of step 2 to `ap`, returning the final result of type `F[C]`.

The definition of `apply3` is similar except that we need three recursive calls to `ap` to completely apply the curried function. `apply4` involves four nested calls to `ap`, and so on.

So, as you can see, while the definition of `ap` appears counter-intuitive at first, it actually provides us with a consistent basis on which to define all methods from `apply2` and up. `ap` is also used to define the formal rules for an applicative:

 - *Identity*: `ap(a)(point(x => x)) == a`
 - *Homomorphism*: `ap(point(a))(point(b)) == point(b(a))`
 - *Interchange*: `ap(point(a))(fb) == ap(fb)(point(x => x(a)))`
 - *Map-like*: `map(fa)(fb) == ap(fa)(point(fb))`

At this point you may be confused. We encourage you not to think of the details of this underlying implementation---you'll only need to know them if you implement an applicative of your own. Let's focus instead on the higher level concepts by looking at some examples of applicatives in action.
