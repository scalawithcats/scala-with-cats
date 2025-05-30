#import "../stdlib.typ": info, warning, solution
== Effectful Interpreters


Let's now turn to effects in interpreters. Sometimes this is an optimisation, and sometimes this is the entire point of using the interpreter strategy. We will look at both, starting with the second.

Remember that the interpreter carries out the actions described in the program or description. These programs can describe effects, like writing to a file or opening a network connection. The interpreter will then carry out these effects. We can still reason about our programs in a simple way using substitution. When we run our programs the effects will happen and we can no longer reason so easily. The goal with the interpreter strategy is to compose the entire program we want to run and then call the interpreter once, so that effects---and the difficulties they cause with reasoning---only happen once.

This will become clearer with an example. Possibly the simplest effect is printing to the standard output, as we can do with `println`. A really simple program describing printing output might have:

- printing a `String` to the standard output; and
- printing a newline to the standard output.

This immediately suggests a description

```scala mdoc:silent
trait Output 
object Output {
  def print(value: String): Output = ???
  def newline: Output = ???
}
```

We're lacking any forms of composition. 
We might want to print some output and then print some more output.
This suggests a method

```scala mdoc:reset:silent
trait Output {
  def andThen(that: Output): Output
}
```

That's a reasonable start, but we can make our programs not much more complex but a lot more interesting by allowing our programs to carry along some value of a generic type, and adding `flatMap` as an operation.

Here's our basic API.

```scala mdoc:reset:silent 
trait Output[A] {
  def flatMap[B](f: A => Output[B]): Output[B]
}
object Output {
  def print(value: String): Output[Unit] = ???
  def newline: Output[Unit] = ???
  def value[A](a: A): Output[A] = ???
}
```

The `value` constructor creates an `Output` that simply returns the given value.

Now we can reify.

```scala mdoc:reset:silent
enum Output[A] {
  case Print(value: String) extends Output[Unit]
  case Newline() extends Output[Unit]
  case FlatMap[A, B](source: Output[A], f: A => Output[B]) extends Output[B]
  case Value(a: A)

  def andThen[B](that: Output[B]): Output[B] =
    this.flatMap(_ => that)

  def flatMap[B](f: A => Output[B]): Output[B] =
    FlatMap(this, f)
}
object Output {
  def print(value: String): Output[Unit] =
    Print(value)

  def newline: Output[Unit] =
    Newline()

  def println(value: String): Output[Unit] =
    print(value).andThen(newline)

  def value[A](a: A): Output[A] =
    Value(a)
}
```

I have added a few conveniences which are defined in terms of the essential operations in our API. This already provides some examples of composition in our algebra.

Finally, let's add an interpreter. I recommend you try implementing this yourself before reading on.

I called the interpreter `run`. Here's the implementation.

```scala
def run(): A =
  this match {
    case Print(value) => print(value)
    case Newline() => println()
    case FlatMap(source, f) => f(source.run()).run()
    case Value(a) => a
  }
```

The first point is that the interpreter actually carries out effects, in this case printing to standard output. The second point is that we can compose descriptions using `flatMap`, or `andThen` which is derived from `flatMap`. Here's an example. First we define a program that, when run, prints `"Hello"`.

```scala mdoc:silent
val hello = Output.print("Hello")
```

Now we can compose this program to create a program that prints `"Hello, Hello?"`.

```scala mdoc:silent
val helloHello = 
  hello.andThen(Output.print(" ,")).andThen(hello).andThen(Output.print("?"))
```

Notice that we reused the the value `hello`, showing composition of programs and reasoning using substitution. 
This only works because `hello` is a description of an effect, not the effect itself.
If we tried to compose the effect, as in the following

```scala
val hello = print("Hello")
val helloHello = {
  hello
  print(" ,")
  hello
  print("?")
}
```

we don't get the output we expect if we use substitution.

We can also mix in pure computation that has no effects.

```scala mdoc:silent
def oddOrEven(phrase: String): Output[Unit] =
  Output
    .value(phrase.size % 2 == 0)
    .flatMap(even =>
      if even then Output.print(s"$phrase has an even number of letters.")
      else Output.print(s"$phrase has an odd number of letters.")
    )
    
helloHello.andThen(Output.print(" ")).andThen(oddOrEven("Scala"))
```


We will now turn to using effects as an optimisation within an interpreter.
In a previous exercise we developed an interpreter for arithmetic expressions.
The code is below.

```scala mdoc:silent
enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)

  def +(that: Expression): Expression =
    Addition(this, that)

  def -(that: Expression): Expression =
    Subtraction(this, that)

  def *(that: Expression): Expression =
    Multiplication(this, that)

  def /(that: Expression): Expression =
    Division(this, that)

  def eval: Double =
    this match {
      case Literal(value)              => value
      case Addition(left, right)       => left.eval + right.eval
      case Subtraction(left, right)    => left.eval - right.eval
      case Multiplication(left, right) => left.eval * right.eval
      case Division(left, right)       => left.eval / right.eval
    }
}
object Expression {
  def apply(value: Double): Expression =
    Literal(value)
}
```

We're going to add a new interpreter that prints expressions.
The straightforward implementation is show below.
For simplicity we fully parenthesize expressions when we print them.

```scala mdoc:reset:silent
enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)

  def +(that: Expression): Expression =
    Addition(this, that)

  def -(that: Expression): Expression =
    Subtraction(this, that)

  def *(that: Expression): Expression =
    Multiplication(this, that)

  def /(that: Expression): Expression =
    Division(this, that)

  def eval: Double =
    this match {
      case Literal(value)              => value
      case Addition(left, right)       => left.eval + right.eval
      case Subtraction(left, right)    => left.eval - right.eval
      case Multiplication(left, right) => left.eval * right.eval
      case Division(left, right)       => left.eval / right.eval
    }
  
  def print: String =
    this match {
      case Literal(value) => value.toString
      case Addition(left, right) => 
        s"(${left.print} + ${right.print})"
      case Subtraction(left, right) => 
        s"(${left.print} - ${right.print})"
      case Multiplication(left, right) => 
        s"(${left.print} * ${right.print})"
      case Division(left, right) => 
        s"(${left.print} / ${right.print})"
    }
}
object Expression {
  def apply(value: Double): Expression =
    Literal(value)
}
```

Here's a short example showing it at work.

```scala mdoc:silent
val expr = Expression(1.0) * Expression(3.0) - Expression(2.0)
```
```scala mdoc
expr.print
```

This implementation suffers from excessive copying of `Strings`.
A more efficient implementation will use a mutable `StringBuilder` to accumulate the result.
It's straightforward to change the `print` interpreter to do this.

```scala
def print: String = {
  val builder = new scala.collection.mutable.StringBuilder()
  
  def withBinOp(left: Expression, op: Char, right: Expression): StringBuilder = {
    builder.addOne('(')
    loop(left)
    builder.addOne(' ')
    builder.addOne(op)
    builder.addOne(' ')
    loop(right)
    builder.addOne(')')
  }

  def loop(expr: Expression): StringBuilder =
    expr match {
      case Literal(value) => builder.append(value.toString)
      case Addition(left, right) => 
        withBinOp(left, '+', right)
      case Subtraction(left, right) => 
        withBinOp(left, '-', right)
      case Multiplication(left, right) => 
        withBinOp(left, '*', right)
      case Division(left, right) => 
        withBinOp(left, '/', right)
    }
    
  loop(this)
  builder.toString
}
```

```scala mdoc:reset:invisible
enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)

  def +(that: Expression): Expression =
    Addition(this, that)

  def -(that: Expression): Expression =
    Subtraction(this, that)

  def *(that: Expression): Expression =
    Multiplication(this, that)

  def /(that: Expression): Expression =
    Division(this, that)

  def eval: Double =
    this match {
      case Literal(value)              => value
      case Addition(left, right)       => left.eval + right.eval
      case Subtraction(left, right)    => left.eval - right.eval
      case Multiplication(left, right) => left.eval * right.eval
      case Division(left, right)       => left.eval / right.eval
    }
  
  def print: String = {
    val builder = new scala.collection.mutable.StringBuilder()
    
    def withBinOp(left: Expression, op: Char, right: Expression): StringBuilder = {
      builder.addOne('(')
      loop(left)
      builder.addOne(' ')
      builder.addOne(op)
      builder.addOne(' ')
      loop(right)
      builder.addOne(')')
    }
  
    def loop(expr: Expression): StringBuilder =
      expr match {
        case Literal(value) => builder.append(value.toString)
        case Addition(left, right) => 
          withBinOp(left, '+', right)
        case Subtraction(left, right) => 
          withBinOp(left, '-', right)
        case Multiplication(left, right) => 
          withBinOp(left, '*', right)
        case Division(left, right) => 
          withBinOp(left, '/', right)
      }
      
    loop(this)
    builder.toString
  }
}
object Expression {
  def apply(value: Double): Expression =
    Literal(value)
}
```

From the outside, the code works exactly as before except it's faster.

```scala mdoc:silent
val expr = Expression(1.0) * Expression(3.0) - Expression(2.0)
```
```scala mdoc
expr.print
```

I haven't benchmarked this implementation, but a similar optimisation in another program made it over 3 times faster. 

We can use side effects, like mutable state, in the interpreter because they are not observable from the outside.
From the user's point of view, what goes on inside the interpreter is not something they can access in any way.
From the point of view of the person writing the interpreter, the mutable state causes the usual problems with reasoning but this is a problem that is contained to a specific piece of code and group of programmers.
