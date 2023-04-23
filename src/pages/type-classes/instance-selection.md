## Controlling Instance Selection

When working with type classes
we must consider two issues
that control instance selection:

 -  What is the relationship between
    an instance defined on a type and its subtypes?

    For example, if we define a `JsonWriter[Option[Int]]`,
    will the expression `Json.toJson(Some(1))` select this instance?
    (Remember that `Some` is a subtype of `Option`).

 -  How do we choose between type class instances
    when there are many available?

    What if we define two `JsonWriters` for `Person`?
    When we write `Json.toJson(aPerson)`,
    which instance is selected?

### Variance {#sec:variance}

When we define type classes we can
add variance annotations to the type parameter
to affect the variance of the type class
and the compiler's ability to select given instances
during resolution.

To recap Essential Scala,
variance relates to subtypes.
We say that `B` is a subtype of `A`
if we can use a value of type `B`
anywhere we expect a value of type `A`.

Co- and contravariance annotations arise
when working with type constructors.
For example, we denote covariance with a `+` symbol:

```scala
trait F[+A] // the "+" means "covariant"
```

**Covariance**

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
enum Shape:
  case Circle(radius: Double)
```

```scala
val circles: List[Shape.Circle] = ???
val shapes: List[Shape] = circles
```

```scala mdoc:invisible
val circles: List[Shape.Circle] = null
val shapes: List[Shape] = circles
```

Generally speaking, covariance is used for outputs:
data that we can later get out of a container type such as `List`,
or otherwise returned by some method.


**Contravariance**

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
trait JsonWriter[-A]:
  def write(value: A): Json
```

Let's unpack this a bit further.
Remember that variance is all about
the ability to substitute one value for another.
Consider a scenario where we have two values,
one of type `Shape` and one of type `Shape.Circle`,
and two `JsonWriters`, one for `Shape` and one for `Shape.Circle`:

```scala
val shape: Shape = ???
val circle: Shape.Circle = ???

val shapeWriter: JsonWriter[Shape] = ???
val circleWriter: JsonWriter[Shape.Circle] = ???
```

```scala mdoc:invisible
val shape: Shape = null
val circle: Shape.Circle = null

val shapeWriter: JsonWriter[Shape] = null
val circleWriter: JsonWriter[Shape.Circle] = null
```

```scala mdoc:silent
def format[A](value: A, writer: JsonWriter[A]): Json =
  writer.write(value)
```

Now ask yourself the question:
"Which combinations of value and writer can I pass to `format`?"
We can `write` a `Shape.Circle` with either writer
because all `Circles` are `Shapes`.
Conversely, we can't write a `Shape` with `circleWriter`
because not all `Shapes` are `Circles`.

This relationship is what we formally model using contravariance.
`JsonWriter[Shape]` is a subtype of `JsonWriter[Shape.Circle]`
because `Shape.Circle` is a subtype of `Shape`.
This means we can use `shapeWriter`
anywhere we expect to see a `JsonWriter[Shape.Circle]`.


**Invariance**

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

When the compiler searches for a given instance
it looks for one matching the type *or subtype*.
Thus we can use variance annotations
to control type class instance selection to some extent.

There are two issues that tend to arise.
Let's imagine we have an algebraic data type like:

```scala
enum A:
  case B, C
```

The issues are:

 1. Will an instance defined on a supertype be selected
    if one is available?
    For example, can we define an instance for `A`
    and have it work for values of type `A.B` and `A.C`?

 2. Will an instance for a subtype be selected
    in preference to that of a supertype.
    For instance, if we define an instance for `A` and `A.B`,
    and we have a value of type `A.B`,
    will the instance for `A.B` be selected in preference to `A`?

It turns out we can't have both at once.
The three choices give us behaviour as follows:

-----------------------------------------------------------------------
Type Class Variance             Invariant   Covariant   Contravariant
------------------------------- ----------- ----------- ---------------
Supertype instance used?        No          No          Yes

More specific type preferred?   No          Yes         No
-----------------------------------------------------------------------

It's clear there is no perfect system.
Cats prefers to use invariant type classes.
This allows us to specify
more specific instances for subtypes if we want.
It does mean that if we have, for example,
a value of type `Some[Int]`,
our type class instance for `Option` will not be used.
We can solve this problem with
a type annotation like `Some(1) : Option[Int]`
or by using "smart constructors"
like the `Option.apply`, `Option.empty`, `some`, and `none` methods
we saw in Section [@sec:type-classes:comparing-options].
