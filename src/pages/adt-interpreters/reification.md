## Interpreters and Reification

There are two different programming strategies at play here:

1. the interpreter strategy; and
2. the interpreter's implementation strategy of reification.

Remember the essence of the **interpreter strategy** is to separate description and action. Therefore whenever we use the interpreter strategy we need at least two things: descriptions and an interpreter that carries out actions. Descriptions are programs; things that we want to happen. The interpreter runs the programs, carrying out the actions described within them.

In the example we just saw, a `Regexp` value is a program. It is a description of a pattern we are looking for within a `String`.
The `matches` method is an interpreter. It carries out the instructions in the description, looking for the pattern within the input. We could have other interpreters, such as one that matches if only the start of the input matches.


### The Structure of Interpreters

All uses of the interpreter strategy have a particular structure to their methods.
There are three different types of methods:

1. constructors, or introduction forms with type `A => Program`, where `A` is any type and `Program` is the type of programs. Constructors conventionally live on the `Program` companion object in Scala. We see that `apply` is a constructor of `Regexp`. It has type `String => Regexp`, which matches the pattern `A => Program` for a constructor.

2. combinators have a program input and output, so the type is similar to `Program => Program` but there are often additional parameters. In our regular expression example, all of `++`, `orElse`, and `repeat` are combinators. They all have a `Regexp` input (the `this` parameter) and produce a `Regexp`. They sometimes have additional parameters, as is the case for `++` or `orElse`. In both these methods the parameter is a `Regexp`, but it is not the case that additional parameters to a combinator must be of the program type. Conventionally these methods live on the `Program` type.

3. destructors, interpreters, or elimination forms, have type `Program => A`. In our regular expression example we have a single interpreter, `matches`, but we could easily add more. For example, we often want to extract elements from the input.

This structure is often called an **algebra** or **combinator library** in the functional programming world. When we talk about constructors and destructors in an algebra we're talking at a more abstract level then when we talk about constructors and destructors on algebraic data types. A constructor of an algebra is an abstract concept, at the theory level in my taxonomy, that we can choose to concretely implement at the craft level with the constructor of an algebraic data type. There are other possible implementations. We'll see one later.


### Implementing Interpreters with Reification

Now that we understand the components of interpreter we can talk more clearly about the implementation strategy we used.
We used a strategy called **reification**, a **deep embedding**, or an **initial algebra**.

Reification, in an abstract sense, means to make concrete what is abstract. Concretely, reification in the programming sense means to turn methods into data. When using reification in the interpreter strategy we reify all the components that produce the `Program` type. This means reifying constructors and combinators.

Here are the rules for reification:

1. We define some type, which we'll call `Program`, to represent programs.
2. We make `Program` an algebraic data type.
3. All constructors and combinators become product types within the `Program` algebraic data type.
4. Each product type holds exactly the parameters to the constructor or combinator, including the `this` parameter for combinators.

Once we've defined the `Program` algebraic data type, the interpreter becomes a structural recursion on `Program`.


### Exercise: Arithmetic {-}

Now it's your turn to practice using reification. Your task is to implement an interpreter for arithmetic expressions. An expression is:

- a literal number, which takes a `Double` and produces an `Expression`;
- an addition of two expressions;
- a substraction of two expressions;
- a multiplication of two expressions; or
- a division of two expressions;

Reify this description as a type `Expression`.

<div class="solution">
```scala mdoc:silent 
enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)
}
object Expression {
  def apply(value: Double): Expression =
    Literal(value)
}
```
</div>

Now implement an interpreter `eval` that produces a `Double`. This interpreter should interpret the expression using the usual rules of arithmetic.

<div class="solution">
```scala mdoc:reset:silent 
enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)
  
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
</div>

Add methods `+`, `-` and so on that make your system a bit nicer to use. Then write some expressions and show that it works as expected.

<div class="solution">
Here's the complete code.

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
}
object Expression {
  def apply(value: Double): Expression =
    Literal(value)
}
```

Here's an example showing use, and that the code is correct.

```scala mdoc:silent
val fortyTwo = ((Expression(15.0) + Expression(5.0)) * Expression(2.0) + Expression(2.0)) / Expression(1.0)
```
```scala mdoc
fortyTwo.eval
```
</div>
