#import "../stdlib.typ": info, warning, solution
== Phantom Types 
<sec:indexed-types:phantom>


Phantom types are a basic building block of indexed types, so we'll start with an example of them. A phantom type is simply a type parameter that doesn't correspond to any value. In the example below, the type parameter `A` is a phantom type, because there is no value of type `A`, while `B` is not because there is a value of that type.

```scala mdoc:silent
final case class PhantomExample[A, B](value: B)
```

Phantom types are used to shift constraints to compile time.
A simple example involves units of measurement. 
Most of the world has standardized on SI units, such as metres and litres. 
However, other measuring systems, such as Imperial units, remain in use some countries or in some niches within countries that otherwise use metric.
Differences between different measurement systems can cause problems.
A dramatic example is the [loss of the Mars orbiter][mars], caused by two software components using incompatible measurements (one using metric, and one using US customary measurements.)

With phantom types we can annotate measurements with their units, which in turn can prevent us ever using incompatible units.
Let's work with just length, which is sufficient to show the idea.
We'll start by defining a length type with a phantom type recording the unit, 
and a method that allows us to add together lengths.

```scala mdoc:silent
final case class Length[Unit](value: Double) {
  def +(that: Length[Unit]): Length[Unit] =
    Length[Unit](this.value + that.value)
}
```

We'll need to define a few unit types to use this, and some `Lengths` using these units.

```scala mdoc:silent
trait Metres
trait Feet

val threeMetres = Length[Metres](3)
val threeFeetAndRising = Length[Feet](3)
```

Now we can add `Lengths` together if they have the same unit.

```scala mdoc
threeMetres + threeMetres
```

However if we try to add `Lengths` with different units the code will not compile.

```scala mdoc:fail
threeMetres + threeFeetAndRising
```

There is one big problem with phantom types on their own: 
there is no way to use the information stored in the phantom type
in further processing.
For example, force times length gives torque (with the SI unit of newton metres).
However we cannot define a `*` method on `Length` that can only be called if the `Unit` is `Metre` using just the tool of phantom types.
Similarly, we cannot define, say, a `toString` method that uses the `Unit` type to appropriately print the result.
Solving these problems leads us to indexed codata, so let's now look at that.

[mars]: https://en.wikipedia.org/wiki/Mars_Climate_Orbiter#Cause_of_failure
