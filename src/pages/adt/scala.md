## Algebraic Data Types in Scala 

Now we know about algebraic data types we can turn to their representation in Scala. The important point here is that the translation to Scala is entirely determined by the structure of the data. No thinking is required. In other words, the work is in finding the structure of the data that best represents the problem at hand. Work out the structure of the data and the code directly follows from it.

As algebraic data types are defined in terms of logical ands and logical ors, to represent algebraic data types in Scala we must know how to represent these two concepts in Scala. Scala 3 simplifies the representation of algebraic data types compared to Scala 2, so we'll look at each separately.

### Algebraic Data Types in Scala 3

In Scala 3 a logical and (a product type) is represented by a `final case class`. If we define a product type `A` is `B` **and** `C`, the representation in Scala 3 is

```scala
final case class A(b: B, c: C)
```

Not everyone makes their case classes `final`, but they should. A non-`final` case class can still be extended by a class, which breaks the closed world criteria for algebraic data types.


A logical or (a sum type) is represented by an `enum`. For the sum type `A` is a `B` **or** `C` the Scala 3 representation is

```scala
enum A {
  case B
  case C
}
```

There are a few wrinkles to be aware of. 

If we have a sum of products, such as:

- `A` is a `B` or `C`; and
- `B` is a `D` and `E`; and
- `C` is a `F` and `G`

the representation is

```scala
enum A {
  case B(d: D, e: E)
  case C(f: F, g: G)
}
```

In other words we don't write `final case class` inside an `enum`. You also can't nest `enum` inside `enum`. Nested logical ors  can be rewritten into a single logical or containing only logical ands (known as disjunctive normal form) so this is not a limitation in practice. However the Scala 2 representation is still available in Scala 3 should you want more expressivity.


### Algebraic Data Types in Scala 2

A logical and (product type) has the same representation in Scala 2 as in Scala 3. If we define a product type `A` is `B` **and** `C`, the representation in Scala 2 is

```scala
final case class A(b: B, c: C)
```

A logical or (a sum type) is represented by a `sealed abstract class`.  For the sum type `A` is a `B` **or** `C` the Scala 2 representation is

```scala
sealed abstract class A
final case class B() extends A
final case class C() extends A
```

Scala 2 has several little tricks to defining algebraic data types.

Firstly, instead of using a `sealed abstract class` you can use a `sealed trait`. There isn't much practical difference between the two. When teaching I'll often use `sealed trait` to avoid having to introduce `abstract class`. I believe `sealed abstract class` has slightly better performance and Java interoperability but I haven't tested this. I also think `sealed abstract class` is closer, semantically, to the meaning of a sum type.

For extra style points we can `extend Product with Serializable` from `sealed abstract class`. Compare the reported types below with and without this little addition.

Let's first see the code without extending `Product` and `Serializable`.

```scala mdoc:silent
sealed abstract class A
final case class B() extends A
final case class C() extends A
```

```scala mdoc
val list = List(B(), C())
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

Finally, if a logical and holds no data we can use a `case object` instead of a `case class`. For example, 
