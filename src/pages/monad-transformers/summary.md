## Summary

In this chapter we introduced monad transformers,
which eliminate the need for nested for comprehensions and pattern matching
when working with "stacks" of nested monads such as below:

```tut:book:silent
import cats.data.Xor
```

```tut:book
val a = Option(Xor.right[String, Int](1))
val b = Option(Xor.right[String, Int](1))

val result = for {
  x <- a
  y <- b
} yield {
  for {
    u <- x
    v <- y
  } yield u + v
}
```

Each monad transformer, such as `FutureT`, `OptionT` or `XorT`,
provides the code needed to merge its related monad with other monads.
The transformer is a data structure that wraps a monad stack,
equipping it with `map` and `flatMap` methods 
that unpack and repack the whole stack:

```tut:book:silent
import cats.data.XorT
```

```tut:book
val wrappedA = XorT(a)
val wrappedB = XorT(b)
```

```tut:book:silent
import cats.instances.option._
```

```tut:book
val wrappedResult = for {
  x <- wrappedA
  y <- wrappedB
} yield x + y

val result = wrappedResult.value
```

The type signatures of monad transformers are written from the inside out,
so an `XorT[Option, String, A]` is a wrapper for an `Option[Xor[String, A]]`.
It is often useful to use type aliases
when writing transformer types for deeply nested monads.

With this look at monad transformers,
we have now covered everything we need to know about monads
and the sequencing of computations using `flatMap`.
In the next chapter we will switch tack
and discuss two new type classes, `Cartesian` and `Applicative`,
that support new kinds of operation such as `zipping`
independent values within a context.
