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

- *Applicative functors*, also known as *applicatives*,
  are a well known functional programming construct
  that appear in many functional programming languages and libraries.
  Cats models these with the `Applicative` type class.

- As we will see later,
  the encoding of applicatives in Scala is slightly cumbersome.
  Cats introduces a simpler type class called `Cartesian`.
  that provides some basic functionality and acts as a basis for `Applicative`.

We will look at `Cartesian` next and then see what `Applicative` adds.
