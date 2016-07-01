## Cartesian Builder Syntax

The `product` method has two main drawbacks:
it only accepts two parameters,
and it can only combine them to create a pair.
Fortunately, Cats provides syntax
to allow us to combine arbitrary numbers of values (well... up to 22 at least)
in a variety of different ways.

We import the syntax, called "cartesian builder" syntax, from `cats.syntax.cartesian`.
Here is an example:

```tut:book
import cats.instances.option._
import cats.syntax.cartesian._

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
val builder = Option(123) |@| Option("abc")

builder.tupled
```

We can use `|@|` repeatedly to create a builder for up to 22 values.
The `tupled` method always returns a tuple of the correct arity:

```tut:book
val builder3 = Option(123) |@| Option("abc") |@| Option(true)

builder2.tupled

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

For example, we can add several nubmers together:

```tut:book
(
  Option(1) |@|
  Option(2)
).map(_ + _)
```

Or zip parameters to create a case class:

```tut:book
case class Cat(name: String, born: Int, color: String)

(
  Option("Garfield") |@|
  Option(1978)       |@|
  Option("Orange and black")
).map(Cat.apply)
```

If we supply a function that accepts the wrong number or types of parameters,
we get a compile error:

```tut:book:fail
(Option(1) |@| Option(2) |@| Option(3)).map(_ + _)
```

```tut:book:fail
(Option(1) |@| Option(true)).map(_ + _)
```
