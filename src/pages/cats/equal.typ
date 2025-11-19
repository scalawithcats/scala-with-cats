#import "../stdlib.typ": info, warning, exercise, solution, href
== Example: Eq


We will finish off this chapter by looking at another useful type class:
#href("http://typelevel.org/cats/api/cats/kernel/Eq.html")[`cats.Eq`].
`Eq` is designed to support _type-safe equality_
and address annoyances using Scala's built-in `==` operator.

Almost every Scala developer has written code like this before:

```scala mdoc:fail
List(1, 2, 3).map(Option(_)).filter(item => item == 1)
```

Ok, many of you won't have made such a simple mistake as this,
but the principle is sound.
The predicate in the `filter` clause always returns `false`
because it is comparing an `Int` to an `Option[Int]`.

This is programmer error---we
should have compared `item` to `Some(1)` instead of `1`.
However, it's not technically a type error because
`==` works for any pair of objects, no matter what types we compare.
`Eq` is designed to add some type safety to equality checks
and work around this problem.#footnote[Scala 3 has it's own solution to this problem, called #href("https://docs.scala-lang.org/scala3/reference/contextual/multiversal-equality.html")[multiversal equality]. It also uses a type class, in this case called `CanEqual`. With the correct imports or compiler flags we can get the compiler to complain if we try to perform an equality check that doesn't make sense. So in practice we don't need `Eq` any more. However it's a simple type class to work with and makes a good introduction to using Cats.]


=== Equality, Liberty, and Fraternity

We can use `Eq` to define type-safe equality
between instances of any given type:

```scala
package cats

trait Eq[A] {
  def eqv(a: A, b: A): Boolean
  // other concrete methods based on eqv...
}
```

The interface syntax, defined in #href("https://www.javadoc.io/doc/org.typelevel/cats-docs_3/latest/cats/syntax/EqSyntax.html")[`cats.syntax.eq`],
provides two methods for performing equality checks
provided there is an instance `Eq[A]` in scope:

 - `===` compares two objects for equality;
 - `=!=` compares two objects for inequality.


=== Comparing Ints


Let's look at a few examples. First we import the type class:

```scala mdoc:silent:reset-object
import cats.*
```

Now let's grab an instance for `Int`:

```scala mdoc:silent
val eqInt = Eq[Int]
```

We can use `eqInt` directly to test for equality:

```scala mdoc
eqInt.eqv(123, 123)
eqInt.eqv(123, 234)
```

Unlike Scala's `==` method,
if we try to compare objects of different types using `eqv`
we get a compile error:

```scala mdoc:fail
eqInt.eqv(123, "234")
```

We can also import the interface syntax
to use the `===` and `=!=` methods:

```scala mdoc:silent
import cats.syntax.all.* // for === and =!=
```

Now the syntax methods are available.

```scala mdoc
123 === 123
123 =!= 234
```

Again, comparing values of different types causes a compiler error:

```scala mdoc:fail
123 === "123"
```

=== Comparing Options 
<sec:type-classes:comparing-options>


Now for a more interesting example---`Option[Int]`.

```scala mdoc:fail
Some(1) === None
```

We have received an error here because the types don't quite match up.
We have `Eq` instances in scope for `Int` and `Option[Int]`
but the values we are comparing are of type `Some[Int]`.
To fix the issue we have to re-type the arguments as `Option[Int]`:

```scala mdoc
(Some(1) : Option[Int]) === (None : Option[Int])
```

We can do this in a friendlier fashion using
the `Option.apply` and `Option.empty` methods from the standard library:

```scala mdoc
Option(1) === Option.empty[Int]
```

or using special syntax from #href("https://www.javadoc.io/doc/org.typelevel/cats-docs_3/latest/cats/syntax/OptionSyntax.html")[`cats.syntax.option`]:

```scala mdoc
1.some === none[Int]
1.some =!= none[Int]
```


=== Comparing Custom Types


We can define our own instances of `Eq` using the `Eq.instance` method,
which accepts a function of type `(A, A) => Boolean` and returns an `Eq[A]`:

```scala mdoc:silent
import java.util.Date

given dateEq: Eq[Date] =
  Eq.instance[Date] { (date1, date2) =>
    date1.getTime === date2.getTime
  }
```

```scala mdoc:silent
val x = new Date() // now
val y = new Date() // a bit later than now
```

```scala mdoc
x === x
x === y
```


#exercise[Equality, Liberty, and Felinity]

Implement an instance of `Eq` for our running `Cat` example:

```scala mdoc:silent
final case class Cat(name: String, age: Int, color: String)
```

Use this to compare the following pairs of objects for equality and inequality:

```scala mdoc:silent
val cat1 = Cat("Garfield",   38, "orange and black")
val cat2 = Cat("Heathcliff", 33, "orange and black")

val optionCat1 = Option(cat1)
val optionCat2 = Option.empty[Cat]
```

#solution[
First we need our Cats imports.
In this exercise we'll be using the `Eq` type class
and the `Eq` interface syntax,
so we start by importing that.

```scala mdoc:silent:reset-object
import cats.*
import cats.syntax.all.* 
```

Our `Cat` class is the same as ever:

```scala mdoc:silent
final case class Cat(name: String, age: Int, color: String)
```

We bring the `Eq` instances for `Int` and `String`
into scope for the implementation of `Eq[Cat]`:

```scala mdoc:silent
given catEqual: Eq[Cat] =
  Eq.instance[Cat] { (cat1, cat2) =>
    (cat1.name  === cat2.name ) &&
    (cat1.age   === cat2.age  ) &&
    (cat1.color === cat2.color)
  }
```

Finally, we test things out in a sample application:

```scala mdoc
val cat1 = Cat("Garfield",   38, "orange and black")
val cat2 = Cat("Heathcliff", 32, "orange and black")

cat1 === cat2
cat1 =!= cat2

val optionCat1 = Option(cat1)
val optionCat2 = Option.empty[Cat]

optionCat1 === optionCat2
optionCat1 =!= optionCat2
```
]
