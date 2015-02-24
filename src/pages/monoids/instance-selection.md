## Controlling Type Class Instance Selection

When working with type classes we must consider two issues the control type class instance selection:

- What is the relationship between an instance defined on a type and its subtypes. For example, if we define a `Monoid[Option]` will the expression `mzero[Some]` select this instance? (Remember that `Some` is a subtype of `Option`).

- How do we choose between type class instances when there are many available. We've seen there are two monoids for `Int`: addition and zero, and multiplication and one. Similarly there are three monoids for `Boolean`. When we write `1 |+| 2`, for example, which instance is selected?

In this section we explore how Scalaz answers these questions.

### Type Class Variance

When we define type classes we can add variance annotations like we can for any other generic type. To quickly recap, there are three cases:

- An unannotated variable like `A` indicates an invariant type. There is no relationship between `Foo[B]` and `Foo[C]` no matter what the sub- or super-type relationship is between `B` and `C`.

- A variable like `+A` indicates a covariant type. If `C` is a subtype of `B`, `Foo[C]` is a subtype of `Foo[B]`.

- A variable like `-A` indicates a contravariant type. If `C` is a supertype of `B`, `Foo[C]` is a subtype of `Foo[B]`.

When the compiler searches for an implicit if looks for one matching the type *or a subtype*. Thus we can use variance annotations to control type class instance selection to some extent.

There are two issues that come up. Let's imagine we have an algebraic data type like

~~~ scala
sealed trait A
final case object B extends A
final case object C extends A
~~~

- Will an type class instance defined on a supertype be selected if one is available? For example, can we define an instance for `A` and have it work for values of type `B` and `C`?

- Will an instance for a subtype be selected in preference to that of a supertype. For instance, if we define an instance for `A` and `B`, and we have a value of type `B`, will the instance for `B` be selected in preference to `A`?

It turns out we can't have both at once. The three choices give us behaviour as follows:

----------------------------------------------------------------------- 
Type Class Variance             Invariant   Covariant   Contravariant  
------------------------------- ----------- ----------- --------------- 
Supertype instance used?        No          No          Yes            
More specific type preferred?   Yes         Yes         No             
----------------------------------------------------------------------- 

It's clear there is no perfect system. Scalaz generally prefers to use invariant type classes. This allows us to specify more specific instances for subtypes, if we want. It does mean that if we have, for example, a value of type `Some[Int]` our monoid instance for `Option` will not be used. We can solve this problem with a type annotation like `Some(1) : Option[Int]` or by using "smart constructors" that construct values with the type of the base trait in an algebraic data type. Scalaz provides these constructors for `Option`, which are called `some` and `none`.

~~~ scala
scala> import scalaz.std.option._
import scalaz.std.option._

scala> some(1)
res0: Option[Int] = Some(1)

scala> none[Int]
res1: Option[Int] = None
~~~

### Instance Selection

The other issue is choosing between type class instances when several are available for a given type. There are two solutions in common use: so-called unboxed tagged types, and value classes.

[Value classes](http://docs.scala-lang.org/overviews/core/value-classes.html) are a feature of Scala 2.10 onwards. They allow us to define types that extend `AnyVal`. In certain situations, creating instances of these types will not cause any runtime allocation to occur. This allows the creation of lightweight wrapper. If we wanted to specify the multiplication instead of sum monoid for `Int` we might wrap our `Int` in a type like

~~~ scala
case class Multiplication[A](wrapped: A) extends AnyVal
~~~

and then define the multiplication monoid for `Multiplication[Int]` instead of defining it for `Int`.

This is not the approach used by Scalaz, as it currently still supports Scala 2.9.3 which in turn does not support value classes. Scalaz instead uses an implementation techinque called [unboxed tagged types](http://docs.typelevel.org/api/scalaz/nightly/index.html#scalaz.Tag$).

The typical way to use tags is to import `scalaz.Tags` and use the constructors defined on it. To use the multiplication monoid we can write

~~~ scala
import scalaz.Tags._
import scalaz.std.anyVal._
import scalaz.syntax.monoid._

Multiplication(1) |+| Multiplication(4)
// res: scalaz.@@[Int,scalaz.Tags.Multiplication] = 4
~~~

Note the result is wrapped in a type tag, though this doesn't alter the runtime representation. To remove the type tag we can do the following

~~~ scala
scala> Multiplication.unwrap(Multiplication(1))
res7: Int = 1

scala> import scalaz.syntax.tag._
import scalaz.syntax.tag._

scala> Multiplication(1).unwrap
res8: Int = 1
~~~

To define methods that accept tagged values we write types like `type @@ tag` (which is an infix version of `@@[type, tag]`).

~~~ scala
import scalaz.@@

def double(in: Int @@ Multiplication): Int @@ Multiplication =
  Multiplication(in.unwrap * 2)
~~~

Finally, to declare our own tags we can do the following:

~~~ scala
import scalaz.Tag

sealed trait ExampleTag
val ExampleTag = Tag.of[ExampleTag]
~~~

There is one important difference between using value classes and tags. A value class creates a new type unrelated to the type it wraps. A tag creates a subtype of the type it tags.
