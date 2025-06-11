#import "../stdlib.typ": info, warning, solution
== Type Classes and Variance


In this section we'll discuss how *variance* interacts
with type class instance selection.
Variance is one of the darker corners of Scala's type system,
so we start by reviewing it
before moving on to its interaction with type classes.


=== Variance 
<sec:variance>


Variance concerns the relationship between 
an instance defined on a type and its subtypes.
For example, if we define a `JsonWriter[Option[Int]]`,
will the expression `Json.toJson(Some(1))` select this instance?
(Remember that `Some` is a subtype of `Option`).

We need two concepts to explain variance: 
type constructors, and subtyping.

Variance applies to any *type constructor*,
which is the `F` in a type `F[A]`.
So, for example, `List`, `Option`, and `JsonWriter` are all type constructors.
A type constructor must have at least one type parameter,
and may have more.
So `Either`, with two type parameters, is also a type constructor.

*Subtyping* is a relationship between types.
We say that `B` is a subtype of `A`
if we can use a value of type `B`
anywhere we expect a value of type `A`.
We may sometimes use the shorthand `B <: A`
to indicate that `B` is a subtype of `A`.

Variance concerns the subtyping relationship between types `F[A]` and `F[B]`,
given a subtyping relationship between `A` and `B`.
If `B` is a subtype of `A` then

+ if `F[B] <: F[A]` we say `F` is *covariant* in `A`; else
+ if `F[B] >: F[A]` we say `F` is *contravariant* in `A`; else
+ if there is no subtyping relationship between `F[B]` and `F[A]` we say `F` is *invariant* in `A`.


When we define a type constructor
we can also add variance annotations to its type parameters.
For example, we denote covariance with a `+` symbol:

```scala
trait F[+A] // the "+" means "covariant"
```

Similarly, the `-` variance annotation indicate contravariance.
If we don't add a variance annotation, the type parameter is invariant.
Let's now look at covariance, contravariance, and invariance in detail.


=== Covariance


Covariance means that the type `F[B]`
is a subtype of the type `F[A]` if `B` is a subtype of `A`.
This is useful for modelling many types,
including collections like `List` and `Option`:

```scala
trait List[+A]
trait Option[+A]
```

The covariance of Scala collections allows
us to substitute collections of one type with a collection of a subtype in our code.
For example, we can use a `List[Circle]`
anywhere we expect a `List[Shape]` because
`Circle` is a subtype of `Shape`:

```scala mdoc:silent
trait Shape
final case class Circle(radius: Double) extends Shape
```

```scala mdoc:silent
val circles: List[Circle] = List(Circle(5.0))
val shapes: List[Shape] = circles
```

Generally speaking, covariance is used for outputs:
data that we can later get out of a container type such as `List`,
or is otherwise returned by some method.


=== Contravariance


What about contravariance?
We write contravariant type constructors
with a `-` symbol like this:

```scala
trait F[-A]
```

Perhaps confusingly, contravariance means that the type `F[B]`
is a subtype of `F[A]` if `A` is a subtype of `B`.
This is useful for modelling types that represent inputs,
like our `JsonWriter` type class above:

```scala mdoc:invisible
trait Json
```

```scala mdoc
trait JsonWriter[-A] {
  def write(value: A): Json
}
```

Let's unpack this a bit further.
Remember that variance is all about
the ability to substitute one value for another.
Consider a scenario where we have two values,
one of type `Shape` and one of type `Circle`,
and two `JsonWriters`, one for `Shape` and one for `Circle`:

```scala
val shape: Shape = ???
val circle: Circle = ???

val shapeWriter: JsonWriter[Shape] = ???
val circleWriter: JsonWriter[Circle] = ???
```

```scala mdoc:invisible
val shape: Shape = null
val circle: Circle = null

val shapeWriter: JsonWriter[Shape] = null
val circleWriter: JsonWriter[Circle] = null
```

We also have a method `format` that expects a `JsonWriter` instance.

```scala mdoc:silent
def format[A](value: A, writer: JsonWriter[A]): Json =
  writer.write(value)
```

Now ask yourself the question:
"Which combinations of value and writer can I pass to `format`?"
We can `write` a `Circle` with either writer
because all `Circles` are `Shapes`.
Conversely, we can't write a `Shape` with `circleWriter`
because not all `Shapes` are `Circles`.

This relationship is what we formally model using contravariance.
`JsonWriter[Shape]` is a subtype of `JsonWriter[Circle]`
because `Circle` is a subtype of `Shape`.
This means we can use `shapeWriter`
anywhere we expect to see a `JsonWriter[Circle]`.


=== Invariance

Invariance is the easiest situation to describe.
It's what we get when we don't write a `+` or `-`
in a type constructor:

```scala
trait F[A]
```

This means the types `F[A]` and `F[B]`
are never subtypes of one another,
no matter what the relationship between `A` and `B`.
This is the default semantics for Scala type constructors.


=== Variance and Instance Selection


When the compiler searches for a given instance
it looks for one matching the type _or subtype_.
Thus we can use variance annotations
to control type class instance selection to some extent.

There are two issues that tend to arise.
Let's imagine we have an algebraic data type like:

```scala mdoc:silent
enum A {
  case B
  case C
}
```

The issues are:

 + Will an instance defined on a supertype be selected
    if one is available?
    For example, can we define an instance for `A`
    and have it work for values of type `B` and `C`?

 + Will an instance for a subtype be selected
    in preference to that of a supertype.
    For instance, if we define an instance for `A` and `B`,
    and we have a value of type `B`,
    will the instance for `B` be selected in preference to `A`?

It turns out we can't have both at once.
The three choices give us behaviour as follows:

#align(center)[
  #table(
      columns: (auto, auto, auto, auto),
      align: left,
      table.header([Type Class Variance], [Invariant], [Covariant], [Contravariant]),
      [Supertype instance used?], [No], [No], [Yes],
      [More specific type preferred?], [No], [Yes], [No]
  )
]

Let's see some examples, using the following types
to show the subtyping relationship.

```scala mdoc:reset:silent
trait Animal
trait Cat extends Animal
trait DomesticShorthair extends Cat
```

Now we'll define three different type classes for the three types of variance, 
and define an instance of each for the `Cat` types.

```scala mdoc:silent
trait Inv[A] {
  def result: String
}
object Inv {
  given Inv[Cat] with
    def result = "Invariant"
    
  def apply[A](using instance: Inv[A]): String =
    instance.result
}

trait Co[+A] {
  def result: String
}
object Co {
  given Co[Cat] with
    def result = "Covariant"

  def apply[A](using instance: Co[A]): String =
    instance.result
}

trait Contra[-A] {
  def result: String
}
object Contra {
  given Contra[Cat] with
    def result = "Contravariant"

  def apply[A](using instance: Contra[A]): String =
    instance.result
}
```

Now the cases that work, all of which select the `Cat` instance.
For the invariant case we must ask for exactly the `Cat` type.
For the covariant case we can ask for a supertype of `Cat`.
For contravariance we can ask for a subtype of `Cat`.

```scala mdoc
Inv[Cat]
Co[Animal]
Co[Cat]
Contra[DomesticShorthair]
Contra[Cat]
```

Now cases that fail.
With invariance any type that is not `Cat` will fail.
So the supertype fails

```scala mdoc:fail
Inv[Animal]
```

as does the subtype.

```scala mdoc:fail
Inv[DomesticShorthair]
```

Covariance fails for any subtype of the type for which the instance is declared.

```scala mdoc:fail
Co[DomesticShorthair]
```

Contravariance fails for any supertype of the type for which the instance is declared.

```scala mdoc:fail
Contra[Animal]
```

It's clear there is no perfect system.
The most common choice is to use invariant type classes.
This allows us to specify
more specific instances for subtypes if we want.
It does mean that if we have, for example,
a value of type `Some[Int]`,
our type class instance for `Option` will not be used.
We can solve this problem with
a type annotation like `Some(1) : Option[Int]`
or by using "smart constructors"
like `Option.apply` and `Option.empty`
which always return a result of type `Option`.
