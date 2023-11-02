## Effectful Interpreters

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


Now let's turn to using effects as an optimisation within an interpreter.
A common feature of regular expresions is the ability to capture selected parts of the input.
For example, if we're using a regular expression to parse `"1979-06-01"` we might wish to capture the numeric parts of the input so we can convert them into the year, month, and day respectively.

We're going to disallow nested captures, which gives us a chance to revisit the finite state machines techniques we saw in the previous chapter. In this model, regular expressions can be in two states: noncapturing or capturing. We'll add a `capture` method that transitions from noncapturing to capturing. There is no transition the other way, nor can we capture a capturing regular expression.

What about the other regular expression methods? Noncapturing regular expressions compose as before. Composing a capturing and noncapturing regular expression produces a capturing regular expression, and composing a capturing and capturing regular expression also produces a capturing expression.

We can sketch out the API for this. 

```scala mdoc:silent
trait Regexp[A] {
  def matches(input: String): Option[A]
}
trait NonCapturing extends Regexp[Unit] {
  def ++(that: NonCapturing): NonCapturing
  def ++[A](that: Capturing[A]): Capturing[A]

  def orElse(that: NonCapturing): NonCapturing
  def ++[A](that: Capturing[A]): Capturing[A]

  def repeat: NonCapturing

  def capture: Capturing[String]
}

trait Capturing[A] extends Regexp[A] {
  def ++(that: NonCapturing): Capturing[A]
  def ++[B](that: Capturing[B]): Capturing[(A, B)]

  wef orElse(that: NonCapturing): Capturing[A]
  def orElse(that: Capturing[A]): Capturing[A]
  
  def map[B](f: A => B): Capturing[B]

  def repeat: Capturing[Seq[A]]
}
```

This shows an interpreter `matches` that is shared between both types of regular expression. The combinators are mostly the same between the two types of regular expression, but we have a lot of repetition due to the differing types.

We can now proceed as usual with reification, except we need to distinguish the different overloads. The simplest solution is to add a case to `Capturing` that represents a `NonCapturing` regular expression that doesn't capture.
