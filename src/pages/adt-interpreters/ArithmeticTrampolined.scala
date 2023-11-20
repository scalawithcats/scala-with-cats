object ArithmeticTrampolined {
  type Continuation = Double => Call

  enum Call {
    case Continue(value: Double, k: Continuation)
    case Loop(expr: Expression, k: Continuation)
    case Done(result: Double)
  }

  enum Expression {
    case Literal(value: Double)
    case Addition(left: Expression, right: Expression)
    case Subtraction(left: Expression, right: Expression)
    case Multiplication(left: Expression, right: Expression)
    case Division(left: Expression, right: Expression)

    def eval: Double = {
      def loop(expr: Expression, cont: Continuation): Call =
        expr match {
          case Literal(value) => Call.Continue(value, cont)
          case Addition(left, right) =>
            Call.Loop(
              left,
              l => Call.Loop(right, r => Call.Continue(l + r, cont))
            )
          case Subtraction(left, right) =>
            Call.Loop(
              left,
              l => Call.Loop(right, r => Call.Continue(l - r, cont))
            )
          case Multiplication(left, right) =>
            Call.Loop(
              left,
              l => Call.Loop(right, r => Call.Continue(l * r, cont))
            )
          case Division(left, right) =>
            Call.Loop(
              left,
              l => Call.Loop(right, r => Call.Continue(l / r, cont))
            )
        }

      def trampoline(call: Call): Double =
        call match {
          case Call.Continue(value, k) => trampoline(k(value))
          case Call.Loop(expr, k)      => trampoline(loop(expr, k))
          case Call.Done(result)       => result
        }

      trampoline(loop(this, x => Call.Done(x)))
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
