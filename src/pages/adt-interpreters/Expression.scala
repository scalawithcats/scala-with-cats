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
