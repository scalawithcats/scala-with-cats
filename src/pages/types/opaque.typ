#import "../stdlib.typ": exercise, solution, href
== Opaque Types <sec:types:opaque-types>

Let's now look at opaque types.
Opaque types are a Scala 3 feature that decouple the representation of a type from the set of allowed operations on that type.
In simpler words, they allow us to create a type (e.g. an `EmailAddress`) that has the same runtime representation as another type (e.g. a `String`),
but is distinct from that type in all other ways.

Here's a definition of `EmailAddress` as an opaque type.

```scala mdoc:silent
opaque type EmailAddress = String
```

This is enough to define the type `EmailAddress` as represented by a `String`.
However, it's a useless definition as it lacks any way to construct an `EmailAddress`.
To properly understand how we can define a constructor, we need to understand that opaque types divide our code base into two distinct parts: where our type is transparent, which is where we know the underlying representation, and the remainder where it is opaque.
The rule is pretty simple: an opaque type is transparent within the scope in which it is defined, so within an enclosing object or class.
If there is no enclosing scope, as in the example above,
it is transparent only within the file in which it is defined.
Everywhere else it is opaque.

Knowing this we can define a constructor.
Following Scala convention we will define it as the `apply` method on the `EmailAddress` companion object.

```scala mdoc:reset:silent
opaque type EmailAddress = String
object EmailAddress {
  def apply(address: String): EmailAddress = {
    assert(
      {
        val idx = address.indexOf('@')
        idx != -1 && address.lastIndexOf('@') == idx
      },
      "Email address must contain exactly one @ symbol."
    )
    address.toLowerCase
  }
}
```

```scala mdoc:invisible:reset
// We need to redefine the opaque type within an object
// to ensure it's not transparent to the following examples
object Opaque {
  opaque type EmailAddress = String
  object EmailAddress {
    def apply(address: String): EmailAddress = {
      assert(
        {
          val idx = address.indexOf('@')
          idx != -1 && address.lastIndexOf('@') == idx
        },
        "Email address must contain exactly one @ symbol."
      )
      address.toLowerCase
    }
  }
}
import Opaque.*
```

The constructor does a basic check on the input (ensuring it contains only one `@` character)
and converts the input to lower case, as email addresses are case insensitive.
I used an `assert` to do the check,
but in a real application we'd probably want a result type that indicates something can go wrong.
More on this below.
Finally, notice that the constructor returns just the `address`,
showing that the representation doesn't change.
Here's an example, showing the result type `EmailAddress`

```scala mdoc
val email = EmailAddress("someone@example.com")
```

This shows that an `EmailAddress` is represented as a `String`,
but as far as the type system is concerned it is not a `String`.
We cannot, for example, call methods defined on `String` on an instance of `EmailAddress`.
#footnote[
    Scala usually runs on the JVM, and the JVM was not designed to support opaque types.
    This means there are, unfortunately, a few ways to poke holes in the abstraction boundary created by an opaque type.
    If we use `isInstanceOf` we can test for the underlying representation.
    Using the methods defined on `Object` (`Any` in Scala), namely `equals`, `hashCode`, and `toString`, also allow us to peek inside.
]

```scala
email.toUpperCase
// Compiler says NO!
```

We can view this as an efficiency gain.
Our `EmailAddress` uses exactly the same amount of memory as the underlying `String` that represents it,
yet it is a different type.
Alternatively, we can view it as a semantic gain.
An `EmailAddress` _is_ a sequence of characters,
the same as a `String`,
but it has additional constraints.
In this case we verify it contains exactly one `@` character,
and ensure it is case insensitive.

We've seen how to define opaque types and their constructors.
What about other methods?
For example, for an `EmailAddress` we might want methods to get the username and domain.
We can use extension methods to do this.
As with the constructor, we just need to define these extension methods in a place where the type is transparent.

```scala mdoc:reset:silent
opaque type EmailAddress = String
extension (address: EmailAddress) {
  def username: String =
    address.substring(0, address.indexOf('@'))

  def domain: String =
    address.substring(address.indexOf('@') + 1, address.size)
}
object EmailAddress {
  def apply(address: String): EmailAddress = {
    assert(
      {
        val idx = address.indexOf('@')
        idx != -1 && address.lastIndexOf('@') == idx
      },
      "Email address must contain exactly one @ symbol."
    )
    address.toLowerCase
  }
}
```

```scala mdoc:invisible
val email = EmailAddress("someone@example.com")
```

With this definition we can use the extension methods as we'd expect.

```scala mdoc
email.username
email.domain
```

There are two other features of opaque types that we should mention:

1. they can have type parameters; and
2. they can have type bounds.

Let's see an example of these two features used together. 
Earlier we saw an example of using an `Option` to represent two different types of database columns:
nullable columns, where `None` mean to set the column to null, and non-nullable, where `None` means to keep the existing value.
We can define these as opaque types with a type parameter.

```scala mdoc:silent
// null is a reserved word in Scala, so we use the name nil
// instead.
opaque type Nilable[+A] = Option[A]
object Nilable {
  def apply[A](value: A): Nilable[A] = Some(value)

  def fromOption[A](option: Option[A]): Nilable[A] = option

  val nil: Nilable[Nothing] = None
}

opaque type Default[+A] = Option[A]
object Default {
  def apply[A](value: A): Default[A] = Some(value)

  def fromOption[A](option: Option[A]): Default[A] = option

  val default: Default[Nothing] = None
}
```

This works just as we'd expect, but we users will probably want to use the `Option` API on `Nilable` and `Default`.
We can avoid tediously reimplementing it as extension methods by declaring that `Nilable` and `Default` are subtypes of `Option`.

```scala mdoc:reset:silent
opaque type Nilable[+A] <: Option[A] = Option[A]
object Nilable {
  def apply[A](value: A): Nilable[A] = Some(value)

  def fromOption[A](option: Option[A]): Nilable[A] = option

  val nil: Nilable[Nothing] = None
}

opaque type Default[+A] <: Option[A] = Option[A]
object Default {
  def apply[A](value: A): Default[A] = Some(value)

  def fromOption[A](option: Option[A]): Default[A] = option

  val default: Default[Nothing] = None
}
```

The type bound `Default[+A] <: Option[A]` says that `Default` is a subtype of `Option`,
and crucially this information is publically available.
Therefore all of the methods on `Option` are available on `Default`.

```scala mdoc:reset:invisible
object Wrapper {
  opaque type Nilable[+A] <: Option[A] = Option[A]
  object Nilable {
    def apply[A](value: A): Nilable[A] = Some(value)
    def fromOption[A](option: Option[A]): Nilable[A] = option
    val nil: Nilable[Nothing] = None
  }
  
  opaque type Default[+A] <: Option[A] = Option[A]
  object Default {
    def apply[A](value: A): Default[A] = Some(value)
    def fromOption[A](option: Option[A]): Default[A] = option
    val default: Default[Nothing] = None
  }
}
import Wrapper.*
```

We can verify this with a few examples.

```scala mdoc
Nilable(1).orElse(Nilable.nil)

Default(1).map(_ + 1)
```

Notice that the results have type `Option`,
because the methods on `Option` that we call have return type `Option`.
We can easily convert back to `Nilable` or `Default` as required by using the `fromOption` constructor.


=== Best Practices

We've seen all the important technical details for opaque types,
so let's now discuss some of the best practices of using them.

The first point I want to address is illustrated by the constructor for `EmailAddress`. 
There is a constraint on the `String` input to the constructor: it must contain an `@` character.
This is a constraint and we should represent this as a type!
We could create another opaque type, called something like `StringWithAnAtCharacter`, but this approach leads to infinite regress.
We cannot push constraints upstream indefinitely.
At some point we have to return a result that indicates the possibility of error.
So our constructor would be better if it returned, say, an `Option` or `Either` to indicate that construction can fail.

There are cases where we know the constructor cannot fail,
but we don't have a convenient way of proving this to the compiler.
For example, if we're loading email addresses from a list that is known to be good, it would be nice to avoid having to writing useless error handling code.
For this reason I recommend including a constructor that doesn't do any validation.
I usually call this method `unsafeApply`, to indicate to the reader that certain checks are not being done.
These changes are shown below.
For simplicity I've used `Option` as the result type to indicate the possibility of failure.

```scala mdoc:reset:silent
type EmailAddress = String
object EmailAddress {
  def apply(address: String): Option[EmailAddress] = {
    val idx = address.indexOf('@')
    if idx != -1 && address.lastIndexOf('@') == idx
    then Some(address.toLowerCase)
    else None
  }

  def unsafeApply(address: String): EmailAddress = address
}
```

We'll almost certainly need to convert from our opaque type back to its underlying type at some point in our code.
I've seen a few conventions for naming such a method; `value` and `get` are popular.
However, I prefer a more descriptive `toType`, replacing `Type` with the concrete type name,
as this extends to conversions to other types.
For `EmailAddress` this means an extension method `toString`, as shown below.
Notice that the method simply returns the `address` value,
once showing the distinction between the type and it's representation as a value.

```scala mdoc:silent
extension (address: EmailAddress) {
  def toString: String = address
}
```


=== Beyond Opaque Types

Opaque types are a lightweight way to add structure---to use types to represent constraints---to our code. However there are two cases where they aren't appropriate.

The first case is when the data requires more structure that we can represent with an opaque type.
For example, a (two-dimensional) point requires two coordinates, so there is no single type that we can use#footnote[
    We could use an `Array[Double]` or `Tuple2[Double, Double]`,
    but it's simpler to just define a class in the usual way.
].
In these cases we're probably looking for an algebraic data type,
which is discussed in @sec:adt.

The second case is when we need to reimplement one of the methods, most commonly `toString`, that opaque types cannot override.
For example,
we might want to ensure that types representing personal information, such as addresses and passwords, cannot be accidentally exposed in logs.
Overriding `toString` helps ensure this, but we cannot do this for opaque types.

