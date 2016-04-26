## Aside: Higher Kinds and Type Constructors

Kinds are like types for types. They describe the number of "holes" in a type. We distinguish between regular types that have no holes, and "type constructors" that have holes that we can fill to produce types.

For example, `List` is a type constructor with one hole. We fill that hole by specifying a parameter to produce a regular type like `List[Int]` or `List[A]`. The trick is not to confuse type constructors with generic types. `List` is a type constructor, `List[A]` is a type:

```scala
List    // type constructor, takes one parameter
List[A] // type, produced using a type parameter
```

There's a close analogy here with functions and values. Functions are "value constructors"---they produce values when we supply parameters:

```scala
math.abs    // function, takes one parameter
math.abs(x) // value, produced using a value parameter
```

<div class="callout callout-warning">
*Kind notation*

We sometimes use "kind notation" to describe the shape of types and their constructors. Regular types have a kind `*`. `List` has kind `* => *` to indicate that it produces a type given a single parameter. `Either` has kind `* => * => *` because it accepts two parameters, and so on.
</div>

In Scala we declare type constructors using underscores but refer to them without:

```scala
// Declare F using underscores:
def myMethod[F[_]] = {

  // Refer to F without underscores:
  val foldable = Foldable.apply[F]

  // ...
}
```

This is analogous to specifying a function's parameters in its definition and omitting them when referring to it:

```scala
// Declare f specifying parameters:
val f = (x: Int) => x * 2

// Refer to f without parameters:
val f2 = f andThen f
```

Armed with this knowledge of type constructors, we can see that the Cats definition of `Foldable` allows us to create instances for any single-parameter type constructor, such as `List`, `Vector`, and `Option`.

<div class="callout callout-info">
*Language feature imports*

Higher kinded types are considered an advanced language feature in Scala. Wherever we declare a type constructor with `A[_]` syntax, we need to "import" the feature to suppress compiler warnings:

```tut:book
import scala.language.higherKinds
```
</div>
