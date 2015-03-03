## Combining Pairs of Values

Applicatives are used to combine values within a context. The `ap` method defines how to combine the contexts, and the `func` parameter defines how to define the values within those contexts. The types on the `ap` method are difficult to parse at first, so we'll start with a simpler example---combining pairs of precisely two values.

Imagine we want to read two numbers from a user and combine them by adding them together. Reading a number may succeed or fail, so the computation as a whole can also fail. Existing Scalaz types such as `\/` presuppose certain combination semantics so we'll define our own `Result` type to model failure in this example. Here's the code:

~~~ scala
// Our Result type:
sealed trait Result[+A]
final case class Pass[+A](value: A) extends Result[A]
final case class Fail(errors: List[String]) extends Result[Nothing]

// Read an Int from the user:
def readInt(str: String): Result[Int] = {
  println("Reading " + str)
  str.parseInt.disjunction.fold(
    exn => Fail(List(s"Error reading $str")),
    num => Pass(num)
  )
}

// Combine two Ints:
def sum2(a: Int, b: Int): Int =
  a + b
~~~

In this example `readInt` provides values within our `Result` context, and `sum2` provides rules for combining values outside the context. We need a combinator to plumb these two together by providing rules for combining the contexts themselves. This is the equivalent of out applicative's `ap` method, except we'll simplify things by restricting it to exactly two arguments:

~~~ scala
def apply2[A, B, C](
  a: => Result[A],
  b: => Result[B],
  func: (A, B) => C): Result[C]
~~~

There are various ways we can define this method depending on the semantics we want. For example, we can choose whether to look at `a` first, `b` first, or both together. We can also choose various strategies for combining errors from `Fail` contexts.

If `Result` is a monad, there's a natural implementation for `apply2` using `map` and `flatMap`:

~~~ scala
def apply2_monadic[A, B, C](
    a: => Result[A],
    b: => Result[B],
    func: (A, B) => C): Result[C] =
  a.flatMap(a => b.map(b => func(a, b)))
~~~

Monadic semantics should be familiar by now. If we can't unpack `a`, we skip unpacking `b` and don't call `func`:

~~~ scala
apply2_monadic(readInt("abc"), readInt("def"), sum2)
// Reading abc
// res17: Result[Int] = Fail(List(Error reading abc))
~~~

`map` and `flatMap` aren't the only way to combine values. Here's an alternative that inspects `a` and `b` but otherwise combines the results with the same semantics as `apply2_monadic`:

~~~ scala
def apply2_keepLeft[A, B, C](
    a: => Result[A],
    b: => Result[B],
    func: (A, B) => C): Result[C] =
  (a, b) match {
    case (Pass(a), Pass(b)) => Pass(func(a, b))
    case (Pass(a), Fail(f)) => Fail(f)
    case (Fail(e), Pass(b)) => Fail(e)
    case (Fail(e), Fail(f)) => Fail(e)
  }
~~~

Note the difference in behaviour when we call this function---although the end result is the same, both `"Reading ..."` messages are printed in the output:

~~~ scala
apply2_keepLeft(readInt("abc"), readInt("def"), sum2)
// Reading abc
// Reading def
// res21: Result[Int] = Fail(List(Error reading abc))
~~~

Finally, here's an implementation that works like `apply2_keepLeft` but keeps all error messages:

~~~ scala
def apply2_keepAll[A, B, C](a: => Result[A], b: => Result[B], func: (A, B) => C): Result[C] =
  (a, b) match {
    case (Pass(a), Pass(b)) => Pass(func(a, b))
    case (Pass(a), Fail(f)) => Fail(f)
    case (Fail(e), Pass(b)) => Fail(e)
    case (Fail(e), Fail(f)) => Fail(e ++ f)
  }

apply2_keepAll(readInt("abc"), readInt("def"), sum2)
// Reading abc
// Reading def
// res22: Result[Int] = Fail(List(Error reading abc, Error reading def))
~~~

These differing implementations demonstrate the generality of applicatives. Every `apply2` method defines a different set of rules for combining contexts. We can use monadic semantics if we want, but there are many other options open to us.

The main limitation of `apply2` is that it only combines *two* contexts. We can nest calls to generalise it to larger arities, but it turns out that this is quite unwieldy. To clean things up we need a new tool---*curried functions*.

### Curried Functions

A curried function accepts its arguments one at a time. The result of providing the first argument is a function that accepts the next argument, and so on until the function call is complete:

~~~ scala
val curriedSum2 = (a: Int) => (b: Int) => a + b
// curriedSum2: Int => (Int => Int) = <function1>

val temp = curriedSum2(1)
// temp: Int => Int = <function1>

temp(2)
// res2: Int = 3
~~~

We can encode any function that accepts arguments as a curried function. The Scala standard library provides the `curried` method to help us with this:

~~~ scala
val sum3 = (a: Int, b: Int, c: Int) => a + b + c
// sum3: (Int, Int, Int) => Int = <function3>

val curried3 = sum3.curried
// curried3: Int => (Int => (Int => Int)) = <function1>

curried3(1)(2)(3)
// res3: Int = 6
~~~

### Currying apply2

We can generalise any of our `apply2` methods by rewriting it to work with curried functions. As an example, here's a generalised version of `apply2_keepAll`. We've called this method `ap` because this is precisely what we would write to define an applicative:

~~~ scala
def ap_keepAll[A, B](a: => Result[A])(b: Result[A => B]): Result[B] =
  (a, b) match {
    case (Pass(a), Pass(b)) => Pass(b(a))
    case (Pass(a), Fail(f)) => Fail(f)
    case (Fail(e), Pass(b)) => Fail(e)
    case (Fail(e), Fail(f)) => Fail(e ++ f)
  }
~~~

At first it could be hard to see the relationship between `ap` and `apply2`. Here's an implementation of `apply2` in terms of `ap` by way of an example:

~~~ scala
def apply2_keepAll[A, B, C](
    a: => Result[A],
    b: => Result[B],
    func: (A, B) => C): Result[C] =
  ap_keepAll(b, ap_keepAll(a, Pass(func.curried)))
~~~

Here's a walk-through of the implementation:

 1. First, we curry `func` and wrap it in a `Pass` to produce a `Result[A => (B => C)]`:

    ~~~ scala
    val inner = Pass(func.curried)
    // inner: Result[A => (B => C)] = ...
    ~~~

 2. We pass `inner` to `ap`, supplying the `a` argument and getting a `Result[B => C]` in return:

    ~~~ scala
    val middle = ap_keepAll(a)(inner)
    // middle: Result[Int => Int] = ...
    ~~~

 3. Finally, we pass `middle` to a second `ap`, supplying `b` and getting back a `Result[C]`:

    ~~~ scala
    val outer = ap_keepAll(b)(middle)
    // outer: Result[Int] = ...
    ~~~

We can see these recursive calls to `ap` as the inverse of currying. Currying turns a flat function into a nest of functions, and the calls to `ap` unpack the nest by injecting arguments one by one. Naturally, this recursive approach generalises to higher arities:

~~~ scala
def apply3_keepAll[A, B, C, D](
    a: => Result[A],
    b: => Result[B],
    func: (A, B, C) => D): Result[D] =
  ap_keepAll(c, ap_keepAll(b, ap_keepAll(a, Pass(func.curried))))
~~~

If this process of recursively calling `ap` seems cumbersome, remember that our definition of applicatives is brought over from Haskell where functions are curried by default. The semantics are the same in both languages but the syntax is much more cleaner in Haskell.

As we shall see in a moment, Scalaz provides several convenience methods and syntaxes that reduce the amount of boilerplate we need to work with high arity functions in Scala.

### Take Home Points

 - Applicative provide mechanisms for combining values within a context.

 - If we have a monad, we can already define a default applicative.
   However, not all applicatives are monads.

 - The type signature on the `ap` method is designed so we can generalise over arity
   using recursive calls and curried functions.
