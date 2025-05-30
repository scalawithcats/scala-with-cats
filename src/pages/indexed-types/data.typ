#import "../stdlib.typ": info, warning, solution
== Indexed Data


The key idea of indexed data is to encode type equalities in data.
When we come to inspect the data (usually, via structural recursion) we discover these equalities, which in turn limit what values we can produce. 
Notice, again, the duality with codata. 
Indexed codata limits methods we can call. 
Indexed data limits values we can produce.
Also, remember that indexed data is often known as generalized algebraic data types.
We are using the simpler term indexed data to emphasise the relationship to indexed codata,
and also because it's much easier to type!

Concretely, indexed data in Scala occurs when:

+ we define a sum type with at least one type parameter; and
+ cases within the sum instantiate that type parameter with a concrete type.

Let's see an example. Imagine we are implementing a programming language. We need some representation of values within the language.
Suppose our language supports strings, integers, and doubles, which we will represent with the corresponding Scala types.
The code below shows how we can implement this as a standard algebraic data type.

```scala mdoc:silent
enum Value {
  case VString(value: String)
  case VInt(value: Int)
  case VDouble(value: Double)
}

```

Using indexed data we can use the alternate implementation below.

```scala mdoc:reset:silent
enum Value[A] {
  case VString(value: String) extends Value[String]
  case VInt(value: Int) extends Value[Int]
  case VDouble(value: Double) extends Value[Double]
}
```

This is indexed data, as it meets the criteria above: we have a type parameter `A` that is instantiated with a concrete type in the cases `VString`, `VInt`, and `VDouble`.
It's quite easy to use indexed data in Scala, and people often do so not knowing that it is anything special.
The natural next question is why is this useful?
It will take a more involved example to show why, so let us now dive into one that makes good use of indexed data.


=== The Probability Monad 


For our case study of indexed data we will create a probability monad. This is a composable abstraction for defining probability distributions. The probability monad has a lot of uses. The most relevant to most developers is generating data for property-based tests, so we'll focus on this use case. However, it can also be used, for example, for statistical inference or for creating generative art. See the conclusions (@sec:indexed-types:conclusions) for some pointers to these uses.

Let's start with an example of generating random data. [Doodle][doodle] is a Scala library for graphics and visualization. A core part of the library is representing colors. Doodle has two different representations of colors, RGB and OkLCH, with conversions between the two. These conversions involve some somewhat tricky mathematics. Testing these conversions is an excellent use of property-based testing. If we can generate many, say, random RGB colors, we can test the conversion by checking the roundrip from RGB to OkLCH and back results in the original color[^numerics]. 

To create an RGB color we need three unsigned bytes, so our first task is to define how we generate a random byte. Doodle happens to have an implementation of the probability monad that we will use. Here is how we can do it.

```scala mdoc:silent
import cats.syntax.all.*
import doodle.core.Color
import doodle.core.UnsignedByte
import doodle.random.{*, given}

val randomByte: Random[UnsignedByte] = 
  Random.int(0, 255).map(UnsignedByte.clip)
```

Note that once again we see the interpreter strategy. A `Random[A]` is a value representing a program that will generate a random value of type `A` when it runs.

With three random unsigned bytes we can create a random RGB color.

```scala mdoc:silent
val randomRGB: Random[Color] =
  (randomByte, randomByte, randomByte)
    .mapN((r, g, b) => Color.rgb(r, g, b))
```

We might want to check our code by generating a few random values.

```scala mdoc
randomRGB.replicateA(2).run
```

It seems to be working.

Once we have a source of random data we can write tests using it. We can easily generate more data than is feasible for a programmer to write by hand, and therefore have a higher degree of certainty that our code is correct than we would get with manual testing. The details of writing the tests are not important to us here, so let's move on.

We have seen is an illustration of using the probability monad to generate random data. The probability monad works the same way as every other algebra: we have constructors (`Random.int`), combinators (`map`, and `mapN`), and interpreters (`run`). Being a monad means the algebra has some specific structure. For example, it tells us that we have `pure` and `flatMap` available, from which we can derive `mapN`.

Let's sketch an plausible interface for our probability monad.

```scala mdoc:reset:silent
trait Random[A] {
  def flatMap[B](f: A => Random[B]): Random[B]
}
object Random {
  def pure[A](value: A): Random[A] = ???
  
  // Generate a uniformly distributed random  Double greater
  // than or equal to zero and less than one.
  val double: Random[Double] = ???
  
  // Generate a uniformly distributed random  Int
  val int: Random[Int] = ???
}
```

The interface has the minimum requirements to be a monad, and a few other constructors. We can make progress on the implementation by applying the reification strategy, introduced in @sec:interpreters:reification.

```scala mdoc:reset:silent
enum Random[A] {
  def flatMap[B](f: A => Random[B]): Random[B] =
    RFlatMap(this, f)

  case RFlatMap[A, B](source: Random[A], f: A => Random[B])
      extends Random[B]
  case RPure(value: A)
  case RDouble extends Random[Double]
  case RInt extends Random[Int]
}
object Random {
  import Random.{RPure, RDouble, RInt}

  def pure[A](value: A): Random[A] = RPure(value)

  // Generate a uniformly distributed random  Double greater
  // than or equal to zero and less than one.
  val double: Random[Double] = RDouble

  // Generate a uniformly distributed random  Int
  val int: Random[Int] = RInt
}
```

The next step is to implement an interpreter, which is a standard structural recursion. The interpreter has a parameter that provides a source of random numbers.

```scala
def run(rng: scala.util.Random = scala.util.Random): A =
  this match {
    case RFlatMap(source, f) => f(source.run(rng)).run(rng)
    case RPure(value)        => value
    case RDouble             => rng.nextDouble()
    case RInt                => rng.nextInt()
  }
```

This is an example of indexed data, as the cases `RDouble` and `RInt` provide a concrete type for the type parameter `A`. This means that these cases in the interpreter can produce values of that concrete type. If we did not use indexed data we could only generate values of type `A`, which the programmer would have to supply to use like in the `RPure` case.

To finish this implementation we should implement the `Monad` type class, which would give us `mapN` and other methods for free. However, this is outside the scope of this case study, which is focused on indexed data. I encourage you to do this yourself if you feel you would benefit from the practice.

Note that indexed data can mix concrete and generic types. Let's say we add a `product` method to `Random`.

```scala mdoc:reset:silent
enum Random[A] {
  // ...

  def product[B](that: Random[B]): Random[(A, B)] =
    RProduct(this, that)

  case RProduct[A, B](left: Random[A], right: Random[B]) extends Random[(A, B)]
  // .. other cases here
}
```

The right-hand side of the `RProduct` case instantiates the type parameter to `(A, B)`, which mixes the concrete tuple type with the generic types `A` and `B`

There are a few tricks to using indexed data that are essential in Scala 2, and can sometimes be useful in Scala 3. Take the following translation of the probability monad into Scala 2. (I've placed a `using` directive in this code, so if you paste it into a file and run it with the Scala CLI it will use the latest version of Scala 2.13.)

```scala mdoc:reset:silent
//> using scala 2.13

sealed trait Random[A] {
  import Random._

  def flatMap[B](f: A => Random[B]): Random[B] =
    RFlatMap(this, f)

  def product[B](that: Random[B]): Random[(A, B)] =
    RProduct(this, that)

  def run(rng: scala.util.Random = scala.util.Random): A =
    this match {
      case RFlatMap(source, f) => f(source.run(rng)).run(rng)
      case RProduct(l, r)      => (l.run(rng), r.run(rng))
      case RPure(value)        => value
      case RDouble             => rng.nextDouble()
      case RInt                => rng.nextInt()
    }

}
object Random {
  final case class RFlatMap[A, B](source: Random[A], f: A => Random[B])
      extends Random[B]
  final case class RProduct[A, B](left: Random[A], right: Random[B])
      extends Random[(A, B)]
  final case class RPure[A](value: A) extends Random[A]
  case object RDouble extends Random[Double]
  case object RInt extends Random[Int]

  def pure[A](value: A): Random[A] = RPure(value)

  // Generate a uniformly distributed random  Double greater
  // than or equal to zero and less than one.
  val double: Random[Double] = RDouble

  // Generate a uniformly distributed random  Int
  val int: Random[Int] = RInt
}
```

In Scala 2 this generates a lot of type errors like

```
[error] constructor cannot be instantiated to expected type;
[error]  found   : Random.RProduct[A(in class RProduct),B]
[error]  required: Random[A(in trait Random)]
[error]       case RProduct(l, r)      => (l.run(rng), r.run(rng))
[error]            ^^^^^^^^
```

To solve this we need to create a nested method with a fresh type parameter in the interpreter, as shown below. With this change Scala 2's type inference works and it can successfully compile the code.

```scala
def run(rng: scala.util.Random = scala.util.Random): A = {
  def loop[A](random: Random[A]): A =
    random match {
      case RFlatMap(source, f)   => loop(f(loop(source)))
      case RProduct(left, right) => (loop(left), loop(right))
      case RPure(value)          => value
      case RDouble               => rng.nextDouble()
      case RInt                  => rng.nextInt()
    }

  loop(this)
}
```

The other trick is for when we want to use pattern matches that match type tags. This means the form like

```scala
case r: RPure[A] => ???
```

rather than

```scala
case RPure(value) => ???
```

For cases like `RProduct` it is not clear how to write these pattern matches, as the type parameters `A` and `B` for `RProduct` don't correspond to the type parameter `A` on `Random`. The solution is use lower case names from the type parameters. Concretely, this means we can write

```scala
case r: RProduct[a, b] => ???
```

The type parameters `a` and `b` are existential types; we know they exist but we don't know what concrete type they correspond to. I've found this is occasionally necessary in Scala 2, but very rare in Scala 3.

[^numerics]: Due to numeric issues there may be small differences between the colors that we should ignore.

[doodle]: https://www.creativescala.org/doodle/
