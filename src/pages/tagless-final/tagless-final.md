## Tagless Final Interpreters

We'll now explore tagless final, an extension to the basic codata interpreter.
In the terminal DSL case study we used an ad-hoc process to produce the DSL, fixing problems as we uncovered them. 
Now we want to be more systematic, illustrating how we can apply strategies to derive code.
This will in turn make it clearer how we can derive tagless final for the basic codata interpreter.

We'll start by being very explicit about the role of the different types in the codata interpreter.
Following Section [@sec:interpreters:structure], remember there are three different kinds of methods in an algebra:

* constructors, with type `A => Program`,
* combinators, with type `Program => Program`, and
* interpreters, with type `Program => A`.

In the terminal DSL we explicitly define the `Program` type as

```scala
type Program[A] = State[Terminal, A]
```

There is a single constructor, `print`, with type `String => Program[Unit]`.
All of the methods that change the output style, such as `bold`, `red`, and `blue`, are combinators with the type `Program[A] => Program[A]`.
Finally, there is a single interpreter, function application, with type `Program[A] => A`.

In a codata interpreter the available interpretations are limited to the methods available on the `Program` type.
The terminal DSL represents programs as functions, and therefore only has a single interpretation available.
The key idea in tagless final, to get around this restriction, is to parameterize the `Program` type by the program operations.
It's not entirely clear what this means, so let's see a simple example of tagless final which will illustrate it.

Our example will be simple arithmetic expressions, which is not very exciting but is familiar.
We'll start with a data interpreter, convert it to a codata interpreter, and then apply tagless final.
Here's our starting point.

```scala mdoc:silent
enum Expr {
  case Add(l: Expr, r: Expr)
  case Sub(l: Expr, r: Expr)
  case Mul(l: Expr, r: Expr)
  case Div(l: Expr, r: Expr)
  
  case Literal(value: Double)
}

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

This defines programs with the algebraic data type `Expr`. Two interpreters, one that evaluates `Expr` to a `Double` and one that prints them to `String`, are implemented using structural recursion.

Here's a quick example. We start by defining an expression, in this case representing `1 + 2`.

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
It is implemented using structural corecursion.

```scala mdoc:reset:silent
trait Expr {
  def +(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = 
        self.eval + that.eval
        
      def print: String =
        s"(${self.print} + ${that.print})"
    }
  }

  def -(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = 
        self.eval - that.eval
        
      def print: String =
        s"(${self.print} - ${that.print})"
    }
  }

  def *(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = 
        self.eval * that.eval
        
      def print: String =
        s"(${self.print} * ${that.print})"
    }
  }

  def /(that: Expr): Expr = {
    val self = this
    new Expr {
      def eval: Double = 
        self.eval / that.eval
        
      def print: String =
        s"(${self.print} / ${that.print})"
    }
  }
    
  def eval: Double
  def print: String
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

However we are restricted to the two interpretations we have defined on `Expr`.

Now, let's consider a program such as `Expr.literal(1) + Expr.literal(2)`.
It is created by calling constructor and combinator methods. We will refer to these as **program algebras**, as they are the portion of the algebra that is used to create programs. The core of tagless final is

1. to define program algebras parameterized by their program type, and
2. to parameterize programs by the program algebras they depend on.

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

Notice how it is parameterized by a type `Expr`. This is the **program type**.

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

We can also define new operations.

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

In this example the program type is the same as the type we interpret to. We can use `Double` as the program type when we want to interpret to `Double`, and likewise with `String`. This is usually *not* the case. It's just a coincidence of using arithmetic as the example that we don't need any additional information to calculate the final result, and hence the program type and interpreter result type are the same. 

There is quite a high notational overhead of tagless final, compared to the data and codata interpreters. We'll address this later, and end up with an encoding of tagless final in Scala that looks like ordinary code. First, however, we'll introduce a more compelling example: cross-platform user interfaces.


### Algebraic User Interfaces

Changing the interpretation of our terminal programs is more a theoretical than a practical problem. While it is true that different interpretations, such as saving to a text buffer, or tracing the state changes, will have niche uses, the vast majority of the time we'll use the default interpretation. A much more motivating example is a cross-platform user interface library. User interfaces targeting the web and mobile platforms is a great source of the value provided by frameworks such as [Flutter](https://flutter.dev/), [React Native](https://reactnative.dev/), and [Capacitor](https://capacitorjs.com/). We'll be a bit less ambitious here, targeting the terminal and the web browser.

Broadly speaking, there are two kinds of user interfaces. When operating, say, a digital musical instrument, we require a continuous stream of values from the user interface. In contrast, when working with a form we only require the values once, when the form is submitted. Modeling a continuous stream of values is certainly doable (see functional reactive programming) but it adds inessential complexity. Therefore we will stick with the simpler kind of interface where the user submits values once.


We'll start by defining the algebra we are working with. Remember that algebras consist of constructors, combinators, and interpreters. Let's consider each in turn. 

Constructors will define the atomic units of user interface our library works with. The granularity we use here trades off expressivity for convenience. At the very lowest level we could work with vertex buffers and the like, which essentially makes our library a general graphics library. This gives us the ultimate flexibility but is far too low level for this case study. At a higher level we might think of atomic units as user interface elements like labels, buttons, text inputs, and so on. This is the level at which HTML operates. At this level we still usually require multiple elements to construct a complete control. For example, in HTML the developer usually has to use a number of DOM elements and Javascript to build common functionality like field validation. We will go even higher level. Our atomic elements will specify the kind of user input we wants, such as a choice between a number of elements, and leave it up to the interpreter to decide how to render this using the platform's available controls. For example, we could render a one-of-many control using either radio buttons or a dropdown, or choose between the two depending on the number of choices. We'll also add labels, and optional validation rules, to each elements. Let's model two such controls, to illustrate the idea.

```scala mdoc:silent
type Validation[A] = A => Either[String, A]

// The validation rule that always succeeds
def succeed[A](value: A): Either[String, A] = Right(value)

trait Controls[Ui[_]] {
  def text(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Ui[String]

  def choice[A](label: String, options: Seq[(String, A)]): Ui[A]
}
```


Here we defined two controls:

- `text`, which creates a text input where the user can enter any text that passes the validation rule; and
- `choice`, which gives the user a choice of one of the given items.

Notice how our modeling decisions restrict our expressivity. For example, `text` can have a placeholder, which is displayed before the user enters input, but does not have a default value. Notice that we don't have any way to control the appearance of controls. This is deliberate; we are pushing that concern into the interpreters. 

These controls generate an element of a type parameter `Ui`. Each particular interpreter, corresponding to a backend, will choose a concrete type for `Ui` corresponding to the needs of the user interface toolkit it is working with.

These two constructors are enough to illustrate the problem, so we will move on to combinators. In the context of user interfaces, the most common combinators will specify the layout of elements. As with the constructors, there are a number of possible designs. We could allow a lot of precision in layout, as CSS does for HTML. In keeping with our design for the constructors, and with the need to keep things simple, we will go with a very high-level design. Our single combinator, `and`, only specifies that two elements should occur together. It leaves it up to the interpreter how this should be achieved on the screen. 

```scala mdoc:silent
trait Layout[Ui[_]] {
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}
```

You might have noticed that `and` is another name for `product` from `Semigroupal`, which we encountered in Section [@sec:semigroupal]. It has exactly the same signature, apart from the name, and it represents the same concept as applied to user interfaces.

The next step is to create an interpreter. Here we are going to create an extremely simple interpreter to illustrate the idea and to allow us to show how to write programs using our algebras. We will write more full featured interpreters later.

Our interpreter will use the very basic Console IO features of the standard library to interact with the user.


```scala mdoc:silent
import cats.syntax.all.*
import scala.io.StdIn
import scala.util.Try

type Program[A] = () => A

object Simple extends Controls[Program], Layout[Program] {
  def and[A, B](first: Program[A], second: Program[B]): Program[(A, B)] =
    // Use Cats Semigroupal for Function0
    (first, second).tupled

  def text(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Program[String] =
    () => {
      def loop(): String = {
        println(s"$label (e.g. $placeholder):")
        val input = StdIn.readLine

        validation(input).fold(
          msg => {
            println(msg)
            loop()
          },
          value => value
        )
      }

      loop()
    }

  def choice[A](label: String, options: Seq[(String, A)]): Program[A] =
    () => {
      def loop(): A = {
        println(label)
        options.zipWithIndex.foreach { case ((desc, _), idx) =>
          println(s"$idx: $desc")
        }

        Try(StdIn.readInt).fold(
          _ => {
            println("Please enter a valid number.")
            loop()
          },
          idx => {
            if idx >= 0 && idx < options.size then options(idx)(1)
            else {
              println("Please enter a valid number.")
              loop()
            }
          }
        )
      }

      loop()
    }
}
```

Now we can implement a simple example.

```scala mdoc:silent
def quiz[Ui[_]](
    controls: Controls[Ui],
    layout: Layout[Ui]
): Ui[(String, Int)] =
  layout.and(
    controls.text("What is your name?", "John Doe"),
    controls.choice(
      "Tagless final is the greatest thing ever",
      Seq(
        "Strongly disagree" -> 1,
        "Disagree" -> 2,
        "Neutral" -> 3,
        "Agree" -> 4,
        "Strongly agree" -> 5
      )
    )
  )
```

We can run this example with code like the following.

```scala
val (name, rating) = quiz(Simple, Simple)()
println(s"Hello $name!")
println(s"Your rating for tagless final is $rating.")
```

Let's recap what we have seen so far:

* We define constructors and combinators as pure interfaces. These interfaces are parameterized by their output type.
* Interpreters implement these interfaces with a concrete type for the output type. The output type is whatever makes sense for this particular interpretation.
* Programs are methods that are parameterized by the output type and the interfaces they need.

The key change, compared to the basic codata interpreter, is the parameterization of the output type. This gives interpreters the flexibility to produce different outputs for different interpretations.
