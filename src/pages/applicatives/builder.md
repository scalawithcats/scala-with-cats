## Cartesian Builder Syntax

The `product` method has two main drawbacks:
it only accepts two parameters,
and it can only combine them to create a pair.
Fortunately, Cats provides syntax
to allow us to combine arbitrary numbers of values (well... up to 22 at least)
in a variety of different ways.

We import the syntax, called "cartesian builder" syntax, from `cats.syntax.cartesian`.
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
creates an intermediate "builder" object that provides
several methods for combining the parameters
to create useful data types.

### Zipping Values and Building Builders

The simplest method of a cartesian builder is `tupled`.
This zips the values using an implicit `Cartesian`:

```scala
val builder2 = Option(123) |@| Option("abc")
// builder2: cats.syntax.CartesianBuilder[Option]#CartesianBuilder2[Int,String] = cats.syntax.CartesianBuilder$CartesianBuilder2@bc0eaef

builder2.tupled
// res1: Option[(Int, String)] = Some((123,abc))
```

We can use `|@|` repeatedly to create builders for up to 22 values.
Each arity of builder, from 2 to 22, defines a `tupled` method
to combine the values to form a tuple of the correct size:

```scala
val builder3 = Option(123) |@| Option("abc") |@| Option(true)
// builder3: cats.syntax.CartesianBuilder[Option]#CartesianBuilder3[Int,String,Boolean] = cats.syntax.CartesianBuilder$CartesianBuilder3@392b690a

builder3.tupled
// res2: Option[(Int, String, Boolean)] = Some((123,abc,true))

val builder5 = builder3 |@| Option(0.5) |@| Option('x')
// builder5: cats.syntax.CartesianBuilder[Option]#CartesianBuilder5[Int,String,Boolean,Double,Char] = cats.syntax.CartesianBuilder$CartesianBuilder5@129e38ff

builder5.tupled
// res3: Option[(Int, String, Boolean, Double, Char)] = Some((123,abc,true,0.5,x))
```

The idiomatic way of using builder syntax is
to combine `|@|` and `tupled` in a single expression,
going from single values to a tuple in one step:

```scala
(
  Option(1) |@|
  Option(2) |@|
  Option(3)
).tupled
// res4: Option[(Int, Int, Int)] = Some((1,2,3))
```

### Combining Values using Custom Functions

In addition to `tupled`,
every builder has a `map` method that accepts a function of the correct arity
and implicit instances of `Cartesian` and `Functor`.
`map` applies the parameters to the function,
allowing us to combine them in any way we choose.

For example, we can add several numbers together:

```scala
(
  Option(1) |@|
  Option(2)
).map(_ + _)
// res5: Option[Int] = Some(3)
```

Or apply parameters to create a case class:

```scala
case class Cat(name: String, born: Int, color: String)
// defined class Cat

(
  Option("Garfield") |@|
  Option(1978)       |@|
  Option("Orange and black")
).map(Cat.apply)
// res6: Option[Cat] = Some(Cat(Garfield,1978,Orange and black))
```

If we supply a function that accepts the wrong number or types of parameters,
we get a compile-time error:

```scala
val add: (Int, Int) => Int = (a, b) => a + b
// add: (Int, Int) => Int = <function2>
```
```scala
(Option(1) |@| Option(2) |@| Option(3)).map(add)
// <console>:19: error: type mismatch;
//  found   : (Int, Int) => Int
//  required: (Int, Int, Int) => ?
//        (Option(1) |@| Option(2) |@| Option(3)).map(add)
//                                                    ^
```
```scala
(Option("cats") |@| Option(true)).map(add)
// <console>:19: error: type mismatch;
//  found   : (Int, Int) => Int
//  required: (String, Boolean) => ?
//        (Option("cats") |@| Option(true)).map(add)
//                                              ^
```
