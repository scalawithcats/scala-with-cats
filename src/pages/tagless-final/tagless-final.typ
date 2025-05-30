#import "../stdlib.typ": info, warning, solution
== Tagless Final Interpreters


We'll now explore tagless final, an extension to the basic codata interpreter.
In the terminal DSL case study we used an ad-hoc process to produce the DSL, fixing problems as we uncovered them. 
In this section we will be more systematic, illustrating how we can apply strategies to derive code.
This will in turn make it clearer how we can derive tagless final for the basic codata interpreter.

We'll start by being explicit about the role of the different types in the codata interpreter.
Following @sec:interpreters:structure, remember there are three different kinds of methods in an algebra:

- constructors, with type `A => Program`,
- combinators, with type `Program => Program`, and
- interpreters, with type `Program => A`.

In the terminal DSL we defined the `Program` type as

```scala
type Program[A] = State[Terminal, A]
```

There is a single constructor, `print`, with type `String => Program[Unit]`.
All of the methods that change the output style, such as `bold`, `red`, and `blue`, are combinators with the type `Program[A] => Program[A]`.
Finally, there is a single interpreter, function application, with type `Program[A] => A`.

In a codata interpreter the available interpretations are limited to the methods available on the `Program` type.
The terminal DSL represents programs as functions, and therefore only has a single interpretation available.
The key idea in tagless final, to get around this restriction, is to parameterize the `Program` type by the program operations.
It's not entirely clear what this means, so let's see a simple example of tagless final to illustrate it.

Our example will be arithmetic expressions. This is not a particularly compelling example, but it is familiar.
This means we can focus on the details of tagless final without any confusion about the domain.
We'll see a more compelling example soon.

We'll start with a data interpreter, convert it to a codata interpreter, and then apply tagless final.
Here's our program type, defined using an algebraic data type.
We don't need to explicitly define constructors as they come as part of the ADT.

```scala mdoc:silent
enum Expr {
  case Add(l: Expr, r: Expr)
  case Sub(l: Expr, r: Expr)
  case Mul(l: Expr, r: Expr)
  case Div(l: Expr, r: Expr)
  
  case Literal(value: Double)
}
```

We will now define two interpreters, one that evaluates `Expr` to a `Double` and one that prints them to `String`. They are implemented using structural recursion.

```scala mdoc:silent
object EvalInterpreter {
  import Expr.*

  def eval(expr: Expr): Double =
    expr match {
      case Add(l, r) => eval(l) + eval(r)
      case Sub(l, r) => eval(l) - eval(r)
      case Mul(l, r) => eval(l) * eval(r)
      case Div(l, r) => eval(l) / eval(r)
      case Literal(value) => value
    }
}
object PrintInterpreter {
  import Expr.*

  def print(expr: Expr): String =
    expr match {
      case Add(l, r) => s"(${print(l)} + ${print(r)})"
      case Sub(l, r) => s"(${print(l)} - ${print(r)})"
      case Mul(l, r) => s"(${print(l)} * ${print(r)})"
      case Div(l, r) => s"(${print(l)} / ${print(r)})"
      case Literal(value) => value.toString
    }
}
```

Finally, let's see a quick example. We start by defining an expression, in this case representing `1 + 2`.

```scala mdoc:silent
val onePlusTwo = Expr.Add(Expr.Literal(1), Expr.Literal(2))
```

Now we can interpret this expression in two different ways.

```scala mdoc
EvalInterpreter.eval(onePlusTwo)
PrintInterpreter.print(onePlusTwo)
```

We have the usual trade-off for data: we can easily add more interpreters, but we cannot extend the program type with new operations.

Let's now convert this to codata.
The interpreters become methods on the `Expr` type.

```scala mdoc:reset:silent
trait Expr {
  def eval: Double
  def print: String
}
```

The constructors and combinators create instances of `Expr`. 
We could define explicit subtypes of `Expr` but here I've used anonymous subtypes to keep the code more compact.
The implementation uses structural corecursion.

```scala mdoc:reset:silent
trait Expr {
  def eval: Double
  def print: String

  def +(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = self.eval + that.eval
      def print: String = s"(${self.print} + ${that.print})"
    }
  }

  def -(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = self.eval - that.eval
      def print: String = s"(${self.print} - ${that.print})"
    }
  }

  def *(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = self.eval * that.eval
      def print: String = s"(${self.print} * ${that.print})"
    }
  }

  def /(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = self.eval / that.eval
      def print: String = s"(${self.print} / ${that.print})"
    }
  }
}
object Expr {
  def literal(value: Double): Expr =
    new Expr {
      def eval: Double = value
      def print: String = value.toString
    }
}
```

Now we can create the same example as before

```scala mdoc:silent
val onePlusTwo = Expr.literal(1) + Expr.literal(2)
```

and interpret it as before

```scala mdoc
onePlusTwo.eval
onePlusTwo.print
```

As expected we have the opposite extensibility. We can add new program operations such as `sin`.

```scala mdoc:silent
def sin(expr: Expr): Expr = {
  new Expr {
    def eval: Double = Math.sin(expr.eval)
    def print: String = s"sin(${expr.print})"
  }
}
```

However we are restricted to the two interpretations we have defined on `Expr`, `eval` and `print`.

We now need to introduce a bit of terminology, so we can talk more precisely.
We will use the term *program algebras* to refer to constructors and combinators, as they are the portion of the algebra used to create programs.
We must also distinguish between programs and the *program type*. 
In the example above, `Expr` is the program type.
A program is an expression that produces a value of the program type.

The core of tagless final is to:

+ define program algebras parameterized by their program type, and
+ parameterize programs by the program algebras they depend on.

For the example we have just seen we could define a program algebra as follows:

```scala mdoc:silent:reset
trait Arithmetic[Expr] {
  def +(l: Expr, r: Expr): Expr
  def -(l: Expr, r: Expr): Expr
  def *(l: Expr, r: Expr): Expr
  def /(l: Expr, r: Expr): Expr
  
  def literal(value: Double): Expr
}
```

Notice how it is parameterized by a type `Expr`. This is the program type.

Now we can create a program.
Here's the same example we saw above, but written in tagless final style.

```scala mdoc:silent
def onePlusTwo[Expr](arithmetic: Arithmetic[Expr]): Expr =
  arithmetic.+(arithmetic.literal(1.0), arithmetic.literal(2.0))
```

Notice the distinction between a program and the program type: a program creates a value of the program type, but a program is not itself of the program type. In tagless final a program is a function from program algebras to the program type.

We can finish our example by creating an instance of `Arithmetic`.

```scala mdoc:silent
object DoubleArithmetic extends Arithmetic[Double] {
  def +(l: Double, r: Double): Double =
    l + r
  def -(l: Double, r: Double): Double =
    l - r
  def *(l: Double, r: Double): Double = 
    l * r
  def /(l: Double, r: Double): Double = 
    l / r
  
  def literal(value: Double): Double =
    value
}
```

Now we can run our example.

```scala mdoc
onePlusTwo(DoubleArithmetic)
```

Tagless final gives us both forms of extensibility. 
We can add a new interpreter.

```scala mdoc:silent
object PrintArithmetic extends Arithmetic[String] {
  def +(l: String, r: String): String =
    s"($l + $r)"
  def -(l: String, r: String): String =
    s"($l - $r)"
  def *(l: String, r: String): String = 
    s"($l * $r)"
  def /(l: String, r: String): String = 
    s"($l / $r)"
  
  def literal(value: Double): String =
    value.toString
}
```

This works in the same way.

```scala mdoc
onePlusTwo(PrintArithmetic)
```

We can also define new program algebras

```scala mdoc:silent
trait Trigonometry[Expr] {
  def sin(expr: Expr): Expr
}
```

and use them in a program.

```scala mdoc:silent
def sinOnePlusTwo[Expr](
    arithmetic: Arithmetic[Expr],
    trigonometry: Trigonometry[Expr]
  ): Expr =
  trigonometry.sin(onePlusTwo(arithmetic))
```

Notice that we are using composition here; the program `sinOnePlusTwo` reuses `onePlusTwo`.

A few notes before we move on.

In this example the program type is the same as the type we interpret to. We can use `Double` as the program type when we want to interpret to `Double`, and likewise with `String`. This is usually _not_ the case. It's just a coincidence of using arithmetic that we don't need any additional information to calculate the final result, and hence the program type and interpreter result type are the same. 

There is quite a high notational overhead of tagless final, compared to the data and codata interpreters. We'll address this later, and end up with an encoding of tagless final in Scala that looks like ordinary code. First, however, we'll introduce a more compelling example: cross-platform user interfaces.
