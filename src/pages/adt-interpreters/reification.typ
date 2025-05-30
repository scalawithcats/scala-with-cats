#import "../stdlib.typ": info, warning, solution
== Interpreters and Reification 
<sec:interpreters:reification>


There are two different programming strategies at play in the regular expression code we've just written:

+ the interpreter strategy; and
+ the interpreter's implementation strategy of reification.

Remember the essence of the *interpreter strategy* is to separate description and action. Therefore, whenever we use the interpreter strategy we need at least two things: a description and an interpreter. Descriptions are programs; things that we want to happen. The interpreter runs the programs, carrying out the actions described within them.

In the regular expression example, a `Regexp` value is a program. It is a description of a pattern we are looking for within a `String`.
The `matches` method is an interpreter. It carries out the instructions in the description, checking the pattern matches the entire input. We could have other interpreters, such as one that matches if at least some part of the input matches the pattern.


=== The Structure of Interpreters 
<sec:interpreters:structure>


All uses of the interpreter strategy have a particular structure to their methods.
There are three different kinds of methods:

+ *constructors*, or *introduction forms*, with type `A => Program`. Here `A` is any type that isn't a program, and `Program` is the type of programs. Constructors conventionally live on the `Program` companion object in Scala. We see that `apply` is a constructor of `Regexp`. It has type `String => Regexp`, which matches the pattern `A => Program` for a constructor. The other constructor, `empty`, is just a value of type `Regexp`. This is equivalent to a method with type `() => Regexp` and so it also matches the pattern for a constructor.

+ *combinators* have at least one program input and a program output. The type is similar to `Program => Program` but there are often additional parameters. All of `++`, `orElse`, and `repeat` are combinators in our regular expression example. They all have a `Regexp` input (the `this` parameter) and produce a `Regexp`. Some of them have additional parameters, such as `++` or `orElse`. For both these methods the single additional parameter is a `Regexp`, but it is not the case that additional parameters to a combinator must be of the program type. Conventionally these methods live on the `Program` type.

+ *destructors*, *interpreters*, or *elimination forms*, have type `Program => A`. In our regular expression example we have a single interpreter, `matches`, but we could easily add more. For example, we often want to extract elements from the input or find a match at any location in the input.

This structure is often called an *algebra* or *combinator library* in the functional programming world. When we talk about constructors and destructors in an algebra we're talking at a more abstract level then when we talk about constructors and destructors on algebraic data types. A constructor of an algebra is an abstract concept, at the theory level in my taxonomy, that we can choose to concretely implement at the craft level with the constructor of an algebraic data type. There are other possible implementations. We'll see one later.


=== Implementing Interpreters with Reification


Now that we understand the components of an interpreter we can talk more clearly about the implementation strategy we used.
We used a strategy called *reification*, *defunctionalization*, *deep embedding*, or an *initial algebra*.

Reification, in an abstract sense, means to make concrete what is abstract. Concretely, reification in the programming sense means to turn methods or functions into data. When using reification in the interpreter strategy we reify all the components that produce the `Program` type. This means reifying constructors and combinators.

Here are the rules for reification:

+ We define some type, which we'll call `Program`, to represent programs.
+ We implement `Program` as an algebraic data type.
+ All constructors and combinators become product types within the `Program` algebraic data type.
+ Each product type holds exactly the parameters to the constructor or combinator, including the `this` parameter for combinators.

Once we've defined the `Program` algebraic data type, the interpreter becomes a structural recursion on `Program`.


==== Exercise: Arithmetic {-}


Now it's your turn to practice using reification. Your task is to implement an interpreter for arithmetic expressions. An expression is:

- a literal number, which takes a `Double` and produces an `Expression`;
- an addition of two expressions;
- a substraction of two expressions;
- a multiplication of two expressions; or
- a division of two expressions;

Reify this description as a type `Expression`.

#solution[
The trick here is to recognize how the textual description relates to code, and to apply reification correctly.

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
]

Now implement an interpreter `eval` that produces a `Double`. This interpreter should interpret the expression using the usual rules of arithmetic.

#solution[
Our interpreter is a structural recursion.

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
]

Add methods `+`, `-` and so on that make your system a bit nicer to use. Then write some expressions and show that it works as expected.

#solution[
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
]
