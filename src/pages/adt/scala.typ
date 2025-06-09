#import "../stdlib.typ": exercise, solution
== Algebraic Data Types in Scala 


Now we know what algebraic data types are, we will turn to their representation in Scala. The important point here is that the translation to Scala is entirely determined by the structure of the data; no thinking is required! This means the work is in finding the structure of the data that best represents the problem at hand. Work out the structure of the data and the code directly follows from it.

As algebraic data types are defined in terms of logical ands and logical ors, to represent algebraic data types in Scala we must know how to represent these two concepts. Scala 3 simplifies the representation of algebraic data types compared to Scala 2, so we'll look at each language version separately.

I'm assuming that you're familiar with the language features we use to represent algebraic data types in Scala, so I won't be going over them.


=== Algebraic Data Types in Scala 3


In Scala 3 a logical and (a product type) is represented by a `final case class`. If we define a product type `A` is `B` _and_ `C`, the representation in Scala 3 is

```scala
final case class A(b: B, c: C)
```

Not everyone makes their case classes `final`, but they should. A non-`final` case class can still be extended by a class, which breaks the closed world criteria for algebraic data types.


A logical or (a sum type) is represented by an `enum`. For the sum type `A` is `B` _or_ `C`, the Scala 3 representation is

```scala
enum A {
  case B
  case C
}
```

There are a few wrinkles to be aware of. 

If we have a sum of products, such as:

- `A` is `B` or `C`; and
- `B` is `D` and `E`; and
- `C` is `F` and `G`

the representation is

```scala
enum A {
  case B(d: D, e: E)
  case C(f: F, g: G)
}
```

In other words we don't write `final case class` inside an `enum`. You also can't nest an `enum` inside an `enum`. Nested logical ors  can be rewritten into a single logical or containing only logical ands (known as disjunctive normal form) so this is not a limitation in practice. However the Scala 2 representation is still available in Scala 3 should you want more expressivity.


=== Algebraic Data Types in Scala 2


A logical and (product type) has the same representation in Scala 2 as in Scala 3. If we define a product type `A` is `B` _and_ `C`, the representation in Scala 2 is

```scala
final case class A(b: B, c: C)
```

A logical or (a sum type) is represented by a `sealed abstract class`.  For the sum type `A` is a `B` _or_ `C` the Scala 2 representation is

```scala
sealed abstract class A
final case class B() extends A
final case class C() extends A
```

Scala 2 has several little tricks to defining algebraic data types.

Firstly, instead of using a `sealed abstract class` you can use a `sealed trait`. There isn't much practical difference between the two. When teaching beginners I'll often use `sealed trait` to avoid having to introduce `abstract class`. I believe `sealed abstract class` has slightly better performance and Java interoperability, but I haven't tested this. I also think `sealed abstract class` is closer, semantically, to the meaning of a sum type.

For extra style points we can `extend Product with Serializable` from `sealed abstract class`. Compare the reported types below with and without this little addition.

Let's first see the code without extending `Product` and `Serializable`.

```scala mdoc:silent
sealed abstract class A
final case class B() extends A
final case class C() extends A
```

```scala mdoc:silent
val list = List(B(), C())
// list: List[A extends Product with Serializable] = List(B(), C())
```

Notice how the type of `list` includes `Product` and `Serializable`. 

Now we have extending `Product` and `Serializable`.

```scala mdoc:reset:silent
sealed abstract class A extends Product with Serializable
final case class B() extends A
final case class C() extends A
```
   
```scala mdoc
val list = List(B(), C())
```

Much easier to read!

You'll only see this in Scala 2. Scala 3 has the concept of *transparent traits*, which aren't reported in inferred types, so you'll see the same output in Scala 3 no matter whether you add `Product` and `Serializable` or not.

Finally, we can use a `case object` instead of a `case class` when we're defining some type that holds no data. For example, reading from a text stream, such as a terminal, can return a character or the end-of-file. We can model this as

```scala mdoc:silent
sealed abstract class Result
final case class Character(value: Char) extends Result
case object Eof extends Result
```

As the end-of-file indicator `Eof` has no associated data we use a `case object`. There is no need to mark the `case object` as `final`, as objects cannot be extended.


=== Examples


Let's make the discussion above more concrete with some examples.


==== Role and User


In the discussion forum example, we said a role is normal, moderator, or administrator. This is a logical or, so we can directly translate it to Scala using the appropriate pattern. In Scala 3 we write

```scala mdoc:silent
enum Role {
  case Normal
  case Moderator
  case Administrator
}
```

In Scala 2 we write

```scala mdoc:reset:silent
sealed abstract class Role extends Product with Serializable
case object Normal extends Role
case object Moderator extends Role
case object Administrator extends Role
```

The cases within a role don't hold any data, so we used a `case object` in the Scala 2 code.

We defined a user as a screen name, an email address, a password, and a role. In both Scala 3 and Scala 2 this becomes

```scala mdoc:silent
final case class User(
  screenName: String,
  emailAddress: String,
  password: String,
  role: Role
)
```

I've used `String` to represent most of the data within a `User`, but in real code we might want to define distinct types for each field.


==== Paths


We defined a path as a sequence of actions of a virtual pen. The possible actions are straight lines, Bezier curves, or movement that doesn't result in visible output. A straight line has an end point (the starting point is implicit), a Bezier curve has two control points and an end point, and a move has an end point. 

This has a straightforward translation to Scala. We can represent paths as the following in both Scala 3 and Scala 2.

```scala mdoc:invisible
type Action = Int
```
```scala mdoc:silent
final case class Path(actions: Seq[Action])
```

An action is a logical or, so we have different representations in Scala 3 and Scala 2. In Scala 3 we'd write

```scala mdoc:reset:invisible
type Point = Int
```
```scala mdoc:silent
enum Action {
  case Line(end: Point)
  case Curve(cp1: Point, cp2: Point, end: Point)
  case Move(end: Point)
}
```

where `Point` is a suitable representation of a two-dimensional point.

In Scala 2 we have to go with the more verbose

```scala mdoc:reset:invisible
type Point = Int
```
```scala mdoc:silent
sealed abstract class Action extends Product with Serializable 
final case class Line(end: Point) extends Action
final case class Curve(cp1: Point, cp2: Point, end: Point)
  extends Action
final case class Move(end: Point) extends Action
```


=== Representing ADTs in Scala 3


We've seen that the Scala 3 representation of algebraic data types, using `enum`, is more compact than the Scala 2 representation. However the Scala 2 representation is still available. Should you ever use the Scala 2 representation in Scala 3? There are a few cases where you may want to:

- Scala 3's doesn't currently support nested `enums` (`enums` within `enums`). This may change in the future, but right now it can be more convenient to use the Scala 2 representation to express this without having to convert to disjunctive normal form.

- Scala 2's representation can express things that are almost, but not quite, algebraic data types. For example, if you define a method on an `enum` you must be able to define it for all the members of the `enum`. Sometimes you want a case of an `enum` to have methods that are only defined for that case. To implement this you'll need to use the Scala 2 representation instead. 


#exercise[Tree]

To gain a bit of practice defining algebraic data types, code the following description in Scala (your choice of version, or do both.)

A `Tree` with elements of type `A` is:

- a `Leaf` with a value of type `A`; or
- a `Node` with a left and right child, which are both `Trees` with elements of type `A`.

#solution[
We can directly translate this binary tree into Scala. Here's the Scala 3 version.

```scala mdoc:silent
enum Tree[A] {
  case Leaf(value: A)
  case Node(left: Tree[A], right: Tree[A])
}
```

In the Scala 2 encoding we write

```scala mdoc:reset:silent
sealed abstract class Tree[A] extends Product with Serializable
final case class Leaf[A](value: A) extends Tree[A]
final case class Node[A](left: Tree[A], right: Tree[A]) extends Tree[A]
```
]
