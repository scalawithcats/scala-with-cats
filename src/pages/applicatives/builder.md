## Cartesian Builder Syntax

The `product` method has two main drawbacks:
it only accepts two parameters,
and it can only combine them to create a pair.
Fortunately, Cats provides syntax
to allow us to combine arbitrary numbers of values
(well... up to 22 at least)
in a variety of different ways.

We import the syntax, called "cartesian builder" syntax,
from `cats.syntax.cartesian`.
Here is an example:

```tut:book:silent
import cats.instances.option._
import cats.syntax.cartesian._
```

```tut:book
(Option(123) |@| Option("abc")).tupled
```

The `|@|` operator, better known as a "tie fighter",
creates an intermediate "builder" object that provides
several methods for combining the parameters
to create useful data types.

### Zipping Values and Building Builders

The simplest method of a cartesian builder is `tupled`.
This zips the values using an implicit `Cartesian`:

```tut:book
val builder2 = Option(123) |@| Option("abc")

builder2.tupled
```

We can use `|@|` repeatedly to create builders for up to 22 values.
Each arity of builder, from 2 to 22, defines a `tupled` method
to combine the values to form a tuple of the correct size:

```tut:book
val builder3 = Option(123) |@| Option("abc") |@| Option(true)

builder3.tupled

val builder5 = builder3 |@| Option(0.5) |@| Option('x')

builder5.tupled
```

The idiomatic way of using builder syntax is
to combine `|@|` and `tupled` in a single expression,
going from single values to a tuple in one step:

```tut:book
(
  Option(1) |@|
  Option(2) |@|
  Option(3)
).tupled
```

### Combining Values using Custom Functions

In addition to `tupled`,
every builder has a `map` method that accepts a function of the correct arity
and implicit instances of `Cartesian` and `Functor`.
`map` applies the parameters to the function,
allowing us to combine them in any way we choose.

For example, we can add several numbers together:

```tut:book
(
  Option(1) |@|
  Option(2)
).map(_ + _)
```

Or apply parameters to create a case class:

```tut:book
case class Cat(name: String, born: Int, color: String)

(
  Option("Garfield") |@|
  Option(1978)       |@|
  Option("Orange and black")
).map(Cat.apply)
```

If we supply a function that accepts the wrong number or types of parameters,
we get a compile-time error:

```tut:book
val add: (Int, Int) => Int = (a, b) => a + b
```

```tut:book:fail
(Option(1) |@| Option(2) |@| Option(3)).map(add)
```

```tut:book:fail
(Option("cats") |@| Option(true)).map(add)
```

### Fancy Functors and Cartesian Builder Syntax

The cartesian builder syntax also supports
[contravariant](#contravariant) and [invariant](#invariant) functors.
In addition to the `tupled` and `map` methods,
each builder also sports `contramap` and `imap` methods
that accept implicit instances of `Contravariant` and `Invariant`.

For example, `Option` is a regular covariant functor,
so we can use it with `map`, `imap`, and `tupled` but not `contramap`:

```tut:book:silent
import cats.instances.option._
import cats.syntax.cartesian._
```

```tut:book
(Option(1) |@| Option(2)).map(_ + _)

(Option(1) |@| Option(2)).tupled

(Option(1) |@| Option(2)).imap((a, b) => List(a, b))(list => (list(0), list(1)))
```

```tut:book:fail
(Option(1) |@| Option(2)).contramap[List[Int]](list => (list(0), list(1)))
```

Note that, surprisingly, the call to `imap` compiles and runs,
even though `Option` has an instance of `Functor` and not `Invariant`.
This is because the `Functor` and `Contravariant` type classes both *extend* `Invariant`.
Each provides sensible behaviour for one direction of mapping in `imap`
and implements the other direction with the `identity` function.

This behaviour seems odd.
In fact, it allows some convenience when it comes to the `tupled` method.
Although we skipped this detail earlier,
`tupled` actually accepts an implicit `Invariant` parameter,
allowing us to use it with any type of functor:
invariant, covariant, or contravariant.
