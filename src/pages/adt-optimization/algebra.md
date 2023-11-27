## Algebraic Manipulation

When we reify a program we represent it as a data structure, which we can then manipulate. 
We're going to return to our regular expression interpreter example, and show how *algebraic manipulation* can be used in two ways: as an algorithm that powers an interpreter, and a way to simplify and therefore optimize the program being interpreted.

We will use a technique known a regular expression derivatives, which provides an extremely simple way to match a regular expression against input with the correct semantics for union (which you may recall we didn't deal with in the previous chapter). As a starting point, let's define what a regular expression derivative is.

The derivative of a regular expression, with respect to a character, is the remaining regular expression after matching the given character. Let's say we have the regular expression that matches the string `"osprey"`. In our library this would be `Regexp("osprey")`. The derivative with respect to the character `o` is `Regexp("sprey")`. The derivative with respect to the character `a` is the regular expression that matches nothing, which is written `Regexp.empty` in our library.

To determine if a regular expression matches some input, all we need to do is calculate successive derivatives with respect to the character in the input in the order they occur. If the resulting regular expression matches the empty string then we have a successful match. Otherwise it has failed to match.

To implement this algorithm we'll need three things:

1. extend our library to explicitly represent the regular expression that matches the empty string;
2. implement a method that tests if a regular expression matches the empty string; and
3. implement a method that computes the derivative of a regular expression with respect to a given character.

Let's go!

Our starting point is the basic reified interpreter we developed in the previous chapter. 
This is the simplest code and therefore the easiest to work with.

```scala mdoc:silent
enum Regexp {
  def ++(that: Regexp): Regexp =
    Append(this, that)

  def orElse(that: Regexp): Regexp =
    OrElse(this, that)

  def repeat: Regexp =
    Repeat(this)

  def `*` : Regexp = this.repeat

  def matches(input: String): Boolean = {
    def loop(regexp: Regexp, idx: Int): Option[Int] =
      regexp match {
        case Append(left, right) =>
          loop(left, idx).flatMap(i => loop(right, i))
        case OrElse(first, second) =>
          loop(first, idx).orElse(loop(second, idx))
        case Repeat(source) =>
          loop(source, idx)
            .flatMap(i => loop(regexp, i))
            .orElse(Some(idx))
        case Apply(string) =>
          Option.when(input.startsWith(string, idx))(idx + string.size)
        case Empty =>
          None
      }

    // Check we matched the entire input
    loop(this, 0).map(idx => idx == input.size).getOrElse(false)
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Empty
}
object Regexp {
  val empty: Regexp = Empty

  def apply(string: String): Regexp =
    Apply(string)
}
```

We want to explicitly represent the regular expression that matches the empty string, as it plays an important part in the algorithms that follow. 
This is simple to do: we just reify it and adjust the constructors as necessary.
I've called this case "epsilon", which matches the terminology used in the literature.

```scala
enum Regexp {
  // ...
  case Epsilon
}
object Regexp {
  val epsilon: Regexp = Epsilon

  def apply(string: String): Regexp =
    if string.isEmpty() then Epsilon
    else Apply(string)
}
```

Next up we need a predicate that tells us if a regular expression matches the empty string. Such a regular expression is called "nullable". The code is so simple it's easier to simply read it than try to explain it in English.

```scala
def nullable: Boolean =
  this match {
    case Append(left, right) => left.nullable && right.nullable
    case OrElse(first, second) => first.nullable || second.nullable
    case Repeat(source) => true
    case Apply(string) => false
    case Epsilon => true
    case Empty => false
  }
```

Now we can implement the actual regular expression derivative.
It consists of two parts: the method to calculate the derivative which in turn depends on a method that handles a nullable regular expression. Both parts are quite simple so I'll give the code first and then explain it.

```scala
def delta: Regexp =
  if nullable then Epsilon else Empty

def derivative(ch: Char): Regexp =
  this match {
    case Append(left, right) =>
      (left.derivative(ch) ++ right).orElse(left.delta ++ right.derivative(ch))
    case OrElse(first, second) =>
      first.derivative(ch).orElse(second.derivative(ch))
    case Repeat(source) =>
      source.derivative(ch) ++ this
    case Apply(string) =>
      if string.size == 1 then
        if string.charAt(0) == ch then Epsilon
        else Empty
      else if string.charAt(0) == ch then Apply(string.tail)
      else Empty
    case Epsilon => Empty
    case Empty => Empty
  }
```

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
For example, we could add the distribution rule $a * (b + c) == (a * b) + (a * c)$.
This rule can increase the size of the expression, so it's not clear to me that adding distribution will keep our rules strongly normalizing.
This is one rule that is strongly normalizing, which is to simply evaluate the entire expression.
In the absence of strongly normalization we can run our rules for a fixed number of iterations.
