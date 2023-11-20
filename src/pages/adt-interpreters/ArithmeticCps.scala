object ArithmeticCps {
  type Continuation = Double => Double

  enum Expression {
    case Literal(value: Double)
    case Addition(left: Expression, right: Expression)
    case Subtraction(left: Expression, right: Expression)
    case Multiplication(left: Expression, right: Expression)
    case Division(left: Expression, right: Expression)

    def eval: Double = {
      def loop(expr: Expression, cont: Continuation): Double =
        expr match {
          case Literal(value) => cont(value)
          case Addition(left, right) =>
            loop(left, l => loop(right, r => cont(l + r)))
          case Subtraction(left, right) =>
            loop(left, l => loop(right, r => cont(l - r)))
          case Multiplication(left, right) =>
            loop(left, l => loop(right, r => cont(l * r)))
          case Division(left, right) =>
            loop(left, l => loop(right, r => cont(l / r)))
        }

      loop(this, identity)
    }

    def +(that: Expression): Expression =
      Addition(this, that)

    def -(that: Expression): Expression =
      Subtraction(this, that)

    def *(that: Expression): Expression =
      Multiplication(this, that)

    def /(that: Expression): Expression =
      Division(this, that)
  }
  object Expression {
    def apply(value: Double): Expression =
      Literal(value)
  }
}
