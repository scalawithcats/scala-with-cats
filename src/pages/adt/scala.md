## Algebraic Data Types in Scala 

Now we know about algebraic data types we can turn to their representation in Scala. The important point here is that the translation to Scala is entirely determined by the structure of the data, no thinking is required. In other words the work is finding the structure of the data that best represents the problem at hand. Work out the structure of the data and the code directly follows from it.

Scala 3 can directly represent algebraic data types using `enum`, but Scala 2 doesn't have this language feature. Hence we'll look at algebraic data types separately in Scala 3 and Scala 2.

As algebraic data types are defined in terms of logical ands and logical ors to represent algebraic data types in Scala we must know how to represent these two concepts in Scala.

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

In other words you can't write `final case class` inside an `enum`. You also can't nest `enum` inside `enum`. Any nested logical or and logical ands can be rewritten into a single logical or containing only logical ands (known as disjunctive normal form) so this is not a limitation in practice. However the Scala 2 representation is still available in Scala 3 should you want more expressivity.


### Algebraic Data Types in Scala 2

