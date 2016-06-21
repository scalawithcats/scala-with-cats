## Cartesian Builder Syntax

Cats provides the `cats.syntax.cartesian` import
to simplify working with `Cartesian`.
Here is an example:

```tut:book
import cats.std.option._
import cats.syntax.cartesian._

(Option(123) |@| Option("abc")).tupled
```

The `|@|` operator, better known as a "tie fighter",
wraps values in an intermediate "cartesian builder" object.
This has several useful methods,
including the `tupled` method seen above.

### Building Builders

The simplest method of a cartesian builder is `tupled`.
This zips the values using an implicit `Cartesian`:

```tut:book
val builder = Option(123) |@| Option("abc")

builder.tupled
```

Cartesian builders also contain a `|@|` method
that adds another value to the builder
(up to a maximum of 22 values):

```tut:book
val builder2 = Option(123) |@| Option("abc")
val builder3 = builder2    |@| Option(true)
val builder4 = builder3    |@| Option(0.5)
val builder5 = builder4    |@| Option('x')
```

### Zipping Values

The `tupled` method on each builder zips all of the accumulated values
into a tuple of the appropriate arity:

```tut:book
builder3.tupled
builder5.tupled
```

In practice, we normally don't hold on to the builder values.
We combine `|@|` and `tupled` in a single statement,
going from single values to a tuple in one step:

```tut:book
(Option(1) |@| Option(2) |@| Option(3)).tupled
```

### Combining Values Using Custom Functions

Although it is useful to combine values as a tuple,
it is much more interesting to combine them as a custom data type.
Every cartesian builder has a `map` method for this purpose:

```tut:book
(Option(1) |@| Option(2)).map(_ + _)
```

Builders keep track of the number and type of parameters collected.
The `map` method always expects a function of the correct arity and type:

```
case class Cat(name: String, born: Int, color: String)

(
  Option("Garfield") |@|
  Option(1978)       |@|
  Option("Orange and black")
).map(Cat.apply)
```

If we supply a function that accepts the wrong number of parameters,
we get a compile error:

```tut:book:fail
(Option(1) |@| Option(2) |@| Option(3)).map(_ + _ + _ + _)
```
