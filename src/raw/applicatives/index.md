# Cartesians and Applicatives {#applicatives}

In previous chapters we saw how functors and monads let us transform values within a context. While these are both immensely useful abstractions, there are types of transformation that we can't represent with either `map` or `flatMap`.

One such example is form validation, where we want to accumulate errors as we go along. If we model this with a monad like `Xor`, we fail fast and lose errors:

```tut:book
import cats.data.Xor

def readInt(str: String): String Xor Int =
  Xor.catchOnly[NumberFormatException](str.toInt).
    leftMap(_ => s"Couldn't read $str")

for {
  a <- readInt("a")
  b <- readInt("b")
  c <- readInt("c")
} yield (a + b + c)
```

To validate forms we need to be able to combine results in parallel:

- try to read each of the three `Ints`;
- if we failed to read one or more `Ints`, return all of the applicable errors;
- if we successfully managed to read all three `Ints`, return their sum.

In this chapter we will look at two type classes that support this pattern:

- The *cartesian* type class encompasses the notion of "zipping" pairs of contexts.
  Cats provides a `CartesianBuilder` syntax that
  combines `Cartesians` and `Functors` to allow users
  to join values within a context using arbitrary functions.

- The *applicative functor* type class, also known simply as *applicative*,
  provides an alternative formulation of cartesian
  in terms of the application of an argument to a function within a context.
  Applicative functors are a common mechanism for joining contexts
  in other functional languages such as Haskell,
  although their formulation in Scala is cumbersome.
