package arithmetic

object Stack {
  enum Expression extends arithmetic.Expression[Expression] {
    def +(that: Expression): Expression =
      Add(this, that)
    def *(that: Expression): Expression =
      Multiply(this, that)
    def -(that: Expression): Expression =
      Subtract(this, that)
    def /(that: Expression): Expression =
      Divide(this, that)

    case Add(left: Expression, right: Expression)
    case Multiply(left: Expression, right: Expression)
    case Subtract(left: Expression, right: Expression)
    case Divide(left: Expression, right: Expression)
    case Literal(value: Double)
  }
  object Expression extends arithmetic.ExpressionConstructors[Expression] {
    def literal(value: Double): Expression =
      Literal(value)
  }

  enum Op {
    case Add
    case Mul
    case Div
    case Sub
  }
}
