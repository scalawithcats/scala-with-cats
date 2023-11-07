## Optimisation

We'll now turn to some techniques for optimizing interpreters.
We have already seen that we can use state in an ad-hoc way for performance improvements.
Here we'll look at two general purpose techniques that apply to a broad range of interpreters: algebraic simplification and stack machines.

### Algebraic Simplification

When we reify a program we represent it as a data structure that we can manipulate. 
These manipulations can include rewriting the data structure to an equivalent but more efficient form.
Recall our arithmetic interpreter:

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

With this we can represent expressions such as `Expression(4.0) * Expression(1.0)`. 
We know algebra has a lot of rules.
For instance, we know that multiplication by one, as in the example above, leaves the other argument unchanged.
So if we see multiplication by one we can just remove it.
(Formally, we say that one is the identity for multiplication.)
We can use a collection of such rules to simplify expressions.
Here's an example.

```scala
def simplify: Expression =
  this match {
    // Addition of identity
    case Addition(Literal(0.0), expr) => expr.simplify
    case Addition(expr, Literal(0.0)) => expr.simplify
    // Multiplication of identity
    case Multiplication(Literal(1.0), expr) => expr.simplify
    case Multiplication(expr, Literal(1.0)) => expr.simplify
    // Multiplication by absorbing element
    case Multiplication(Literal(0.0), expr) => Literal(0.0)
    case Multiplication(expr, Literal(0.0)) => Literal(0.0)
    // Subtraction of identity
    case Subtraction(expr, Literal(0.0)) => expr.simplify
    // Division of identity
    case Division(expr, Literal(1.0)) => expr.simplify
    // Cases with no special treatment
    case Literal(value) =>
      Literal(value)
    case Addition(left, right) =>
      Addition(left.simplify, right.simplify)
    case Subtraction(left, right) =>
      Subtraction(left.simplify, right.simplify)
    case Multiplication(left, right) =>
      Multiplication(left.simplify, right.simplify)
    case Division(left, right) =>
      Division(left.simplify, right.simplify)
  }
```

Conceptually this is an interpreter, because it uses structural recursion, even though the result is of our program type.

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

  def simplify: Expression =
    this match {
      // Addition of identity
      case Addition(Literal(0.0), expr) => expr.simplify
      case Addition(expr, Literal(0.0)) => expr.simplify
      // Multiplication of identity
      case Multiplication(Literal(1.0), expr) => expr.simplify
      case Multiplication(expr, Literal(1.0)) => expr.simplify
      // Multiplication by absorbing element
      case Multiplication(Literal(0.0), expr) => Literal(0.0)
      case Multiplication(expr, Literal(0.0)) => Literal(0.0)
      // Subtraction of identity
      case Subtraction(expr, Literal(0.0)) => expr.simplify
      // Division of identity
      case Division(expr, Literal(1.0)) => expr.simplify
      // Cases with no special treatment
      case Literal(value) =>
        Literal(value)
      case Addition(left, right) =>
        Addition(left.simplify, right.simplify)
      case Subtraction(left, right) =>
        Subtraction(left.simplify, right.simplify)
      case Multiplication(left, right) =>
        Multiplication(left.simplify, right.simplify)
      case Division(left, right) =>
        Division(left.simplify, right.simplify)
    }

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

    def withBinOp(
        left: Expression,
        op: Char,
        right: Expression
    ): StringBuilder = {
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

We can see that `simplify` does indeed work.

```scala mdoc
(Expression(4.0) + Expression(0.0)).simplify.print
(Expression(1.0) * Expression(0.0)).simplify.print
```

However it misses some opportunities for simplification, such as when one simplification opens up the opportunity for another.

```scala mdoc
(Expression(4.0) * (Expression(0.0) + Expression(1.0))).simplify.print
```

There's no general purpose solution to this problem.
It depends on the nature of the structure we are simplifying and the rules we are using.
If repeated application of the rules is guaranteed to terminate in an expression that has no further possible simplifications, we call the rules **strongly normalizing**. 
An expression that has no possible further simplifications is said to be in a **normal form**.
We have already seen one example of a normal form when discussing algebraic data types, where we talked about disjunctive normal form.
Finally, if we can apply a function or method to it's own output, and it reaches a value where the input and the output are the same, we say the function or method has a **fixed point**.
If rewrite have a fixed point for all possible inputs then they are strongly normalizing.

Our example, `simplify`, has a fixed point for all its inputs. This is because every rule makes the output the same or smaller than the input. Therefore repeated application of the rules is guaranteed to eventually stop.
We can `simplify` until a fixed point with the following change.

```scala
def simplify: Expression = {
  def loop(expr: Expression): Expression = {
    val result =
      expr match {
        // Addition of identity
        case Addition(Literal(0.0), expr) => expr.simplify
        case Addition(expr, Literal(0.0)) => expr.simplify
        // Multiplication of identity
        case Multiplication(Literal(1.0), expr) => expr.simplify
        case Multiplication(expr, Literal(1.0)) => expr.simplify
        // Multiplication by absorbing element
        case Multiplication(Literal(0.0), expr) => Literal(0.0)
        case Multiplication(expr, Literal(0.0)) => Literal(0.0)
        // Subtraction of identity
        case Subtraction(expr, Literal(0.0)) => expr.simplify
        // Division of identity
        case Division(expr, Literal(1.0)) => expr.simplify
        // Cases with no special treatment
        case Literal(value) =>
          Literal(value)
        case Addition(left, right) =>
          Addition(left.simplify, right.simplify)
        case Subtraction(left, right) =>
          Subtraction(left.simplify, right.simplify)
        case Multiplication(left, right) =>
          Multiplication(left.simplify, right.simplify)
        case Division(left, right) =>
          Division(left.simplify, right.simplify)
      }

    if result == expr then result else loop(result)
  }

  loop(this)
}
```

Now more simplifications will be made.

```scala mdoc:invisible:reset
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

  def simplify: Expression = {
    def loop(expr: Expression): Expression = {
      val result =
        expr match {
          // Addition of identity
          case Addition(Literal(0.0), expr) => expr.simplify
          case Addition(expr, Literal(0.0)) => expr.simplify
          // Multiplication of identity
          case Multiplication(Literal(1.0), expr) => expr.simplify
          case Multiplication(expr, Literal(1.0)) => expr.simplify
          // Multiplication by absorbing element
          case Multiplication(Literal(0.0), expr) => Literal(0.0)
          case Multiplication(expr, Literal(0.0)) => Literal(0.0)
          // Subtraction of identity
          case Subtraction(expr, Literal(0.0)) => expr.simplify
          // Division of identity
          case Division(expr, Literal(1.0)) => expr.simplify
          // Cases with no special treatment
          case Literal(value) =>
            Literal(value)
          case Addition(left, right) =>
            Addition(left.simplify, right.simplify)
          case Subtraction(left, right) =>
            Subtraction(left.simplify, right.simplify)
          case Multiplication(left, right) =>
            Multiplication(left.simplify, right.simplify)
          case Division(left, right) =>
            Division(left.simplify, right.simplify)
        }

      if result == expr then result else loop(result)
    }

    loop(this)
  }

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

    def withBinOp(
        left: Expression,
        op: Char,
        right: Expression
    ): StringBuilder = {
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

```scala mdoc
(Expression(4.0) * (Expression(0.0) + Expression(1.0))).simplify.print
```
However, even though it's strongly normalizing there are still additional simplifications that we could add to our rule set. 
For example, we could add the distribution rule `a * (b + c) == (a * b) + (a * c)`.
This rule can increase the size of the expression, so it's not clear to me that adding distribution is strongly normalizing.
In the absence of strongly normalizing we can run our rules for a fixed number of iterations.
