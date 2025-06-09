#import "../stdlib.typ": info, warning, solution, exercise
== The Algebra of Algebraic Data Types


A question that sometimes comes up is where the "algebra" in algebraic data types comes from. I want to talk about this a little bit and show some of the algebraic manipulations that can be done on algebraic data types.

The term algebra is used in the sense of abstract algebra, an area of mathematics.
Abstract algebra deals with algebraic structures. 
An algebraic structure consists of a set of values, operations on that set, and properties that those operations must maintain.
An example is the set of integers, the operations addition and multiplication, and the familiar properties of these operations such as associativity, which says that $a + (b + c) = (a + b) + c$.
The abstract in abstract algebra means that it doesn't deal with concrete values like integers---that would be far too easy to understand---and instead with abstractions with wacky names like semigroup, monoid, and ring.
The example of integers above is an instance of a ring.
We'll see a lot more of these soon enough!

Algebraic data types also correspond to the algebraic structure called a ring.
A ring has two operations, which are conventionally written $+$ and $times$.
You'll perhaps guess that these correspond to sum and product types respectively, and you'd be absolutely correct.
What about the properties of these operations?
We'll they are similar to what we know from basic algebra:

- $+$ and $times$ are associative, so $a + (b + c) = (a + b) + c$ and likewise for $times$;
- $a + b = b + a$, known as commutivitiy;
- there is an identity $0$ such that $a + 0 = a$;
- there is an identity $1$ such that $a times 1 = a$;
- there is distribution, so that $a times (b + c) = (a times b) + (a times c)$

So far, so abstract. 
Let's make it concrete by looking at actual examples in Scala.

Remember the algebraic data types work with types, so the operations $+$ and $times$ take types as parameters.
So $"Int" times "String"$ is equivalent to

```scala mdoc:silent
final case class IntAndString(int: Int, string: String)
```

We can use tuples to avoid creating lots of names.

```scala mdoc:reset:silent
type IntAndString = (Int, String)
```

We can do the same thing for $+$. $"Int" + "String"$ is

```scala mdoc:silent
enum IntOrString {
  case IsInt(int: Int)
  case IsString(string: String)
}
```

or just

```scala mdoc:reset:silent
type IntOrString = Either[Int, String]
```


#exercise[Identities]


Can you work out which Scala type corresponds to the identity $1$ for product types?

#solution[
It's `Unit`, because adding `Unit` to any product doesn't add any more information.
So, `Int` contains exactly as much information as $"Int" times "Unit"$ (written as the tuple `(Int, Unit)` in Scala).
]

What about the Scala type corresponding to the identity $0$ for sum types?

#solution[
It's `Nothing`, following the same reasoning as products: a case of `Nothing` adds no further information (and we cannot even create a value with this type.)
]


What about the distribution law? This allows us to manipulate algebraic data types to form equivalent, but perhaps more useful, representations.
Consider this example of a user data type.

```scala mdoc:silent
final case class Person(name: String, permissions: Permissions)
enum Permissions {
  case User
  case Moderator
}
```

Written in mathematical notation, this is

$
    "Person" &= "String" times "Permissions" \
    "Permissions" &= "User" + "Moderator"
$

Performing substitution gets us

$
"Person" = "String" times ("User" + "Moderator")
$

Applying distribution results in

$
"Person" = ("String" times "User") + ("String" times "Moderator")
$

which in Scala we can represent as

```scala mdoc:reset:silent
enum Person {
  case User(name: String)
  case Moderator(name: String)
}
```

Is this representation more useful? I can't say without the context of where the data is being used. However I can say that knowing this manipulation is possible, and correct, is useful.

There is a lot more that could be said about algebraic data types, but at this point I feel we're really getting into the weeds.
I'll finish up with a few pointers to other interesting facts:

- Exponential types exist. They are functions! A function `A => B` is equivalent to $b^a$.
- Quotient types also exist, but they are a bit weird. Read up about them if you're interested.
- Another interesting algebraic manipulation is taking the derivative of an algebraic data type. This gives us a kind of iterator, known as a zipper, for that type.
