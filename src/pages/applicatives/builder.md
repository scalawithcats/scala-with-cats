## Cartesian Builder Syntax

Cats provides the `cats.syntax.cartesian` import
to simplify working with `Cartesian`.
Here is an example:

```scala
import cats.instances.option._
// import cats.instances.option._

import cats.syntax.cartesian._
// import cats.syntax.cartesian._

(Option(123) |@| Option("abc")).tupled
// res0: Option[(Int, String)] = Some((123,abc))
```

The `|@|` operator, better known as a "tie fighter",
wraps values in an intermediate "cartesian builder" object.
This has several useful methods,
including the `tupled` method seen above.

### Zipping Values and Building Builders

The simplest method of a cartesian builder is `tupled`.
This zips the values using an implicit `Cartesian`:

```scala
val builder = Option(123) |@| Option("abc")
// builder: cats.syntax.CartesianBuilder[Option]#CartesianBuilder2[Int,String] = cats.syntax.CartesianBuilder$CartesianBuilder2@38e3a40c

builder.tupled
// res1: Option[(Int, String)] = Some((123,abc))
```

Cartesian builders also contain a `|@|` method
that adds another value to the builder
(up to a maximum of 22 values):

```scala
val builder2 = Option(123) |@| Option("abc")
// builder2: cats.syntax.CartesianBuilder[Option]#CartesianBuilder2[Int,String] = cats.syntax.CartesianBuilder$CartesianBuilder2@61959476

val builder3 = builder2    |@| Option(true)
// builder3: cats.syntax.CartesianBuilder[Option]#CartesianBuilder3[Int,String,Boolean] = cats.syntax.CartesianBuilder$CartesianBuilder3@475fa7c2

val builder4 = builder3    |@| Option(0.5)
// builder4: cats.syntax.CartesianBuilder[Option]#CartesianBuilder4[Int,String,Boolean,Double] = cats.syntax.CartesianBuilder$CartesianBuilder4@5e528553

val builder5 = builder4    |@| Option('x')
// builder5: cats.syntax.CartesianBuilder[Option]#CartesianBuilder5[Int,String,Boolean,Double,Char] = cats.syntax.CartesianBuilder$CartesianBuilder5@7a016e63
```

The `tupled` method on each builder zips all of the accumulated values
into a tuple of the appropriate arity:

```scala
builder3.tupled
// res2: Option[(Int, String, Boolean)] = Some((123,abc,true))

builder5.tupled
// res3: Option[(Int, String, Boolean, Double, Char)] = Some((123,abc,true,0.5,x))
```

In practice, we normally don't hold on to the builder values.
We combine `|@|` and `tupled` in a single statement,
going from single values to a tuple in one step:

```scala
(Option(1) |@| Option(2) |@| Option(3)).tupled
// res4: Option[(Int, Int, Int)] = Some((1,2,3))
```

### Combining Values using Custom Functions

Although it is useful to combine values as a tuple,
it is much more interesting to combine them as a custom data type.
Every cartesian builder has a `map` method for this purpose:

```scala
(Option(1) |@| Option(2)).map(_ + _)
// res5: Option[Int] = Some(3)
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

```scala
(Option(1) |@| Option(2) |@| Option(3)).map(_ + _)
// <console>:18: error: missing parameter type for expanded function ((x$1, x$2) => x$1.$plus(x$2))
//        (Option(1) |@| Option(2) |@| Option(3)).map(_ + _)
//                                                    ^
// <console>:18: error: missing parameter type for expanded function ((x$1: <error>, x$2) => x$1.$plus(x$2))
//        (Option(1) |@| Option(2) |@| Option(3)).map(_ + _)
//                                                        ^
```
