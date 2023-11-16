package regexp

object Trampolined {
  // Define a type alias so we can easily write continuations
  type Continuation = Option[Int] => Call

  enum Call {
    case Loop(regexp: Regexp, index: Int, continuation: Continuation)
    case Continue(index: Option[Int], continuation: Continuation)
    case Done(index: Option[Int])
  }

  enum Regexp extends regexp.Regexp[Regexp] {
    def ++(that: Regexp): Regexp =
      Append(this, that)

    def orElse(that: Regexp): Regexp =
      OrElse(this, that)

    def repeat: Regexp =
      Repeat(this)

    def `*` : Regexp = this.repeat

    def matches(input: String): Boolean = {
      def loop(regexp: Regexp, idx: Int, cont: Continuation): Call =
        regexp match {
          case Append(left, right) =>
            val k: Continuation = _ match {
              case None    => Call.Continue(None, cont)
              case Some(i) => Call.Loop(right, i, cont)
            }
            Call.Loop(left, idx, k)

          case OrElse(first, second) =>
            val k: Continuation = _ match {
              case None => Call.Loop(second, idx, cont)
              case some => Call.Continue(some, cont)
            }
            Call.Loop(first, idx, k)

          case Repeat(source) =>
            val k: Continuation =
              _ match {
                case None    => Call.Continue(Some(idx), cont)
                case Some(i) => Call.Loop(regexp, i, cont)
              }
            Call.Loop(source, idx, k)

          case Apply(string) =>
            Call.Continue(
              Option.when(input.startsWith(string, idx))(idx + string.size),
              cont
            )

          case Empty =>
            Call.Continue(None, cont)
        }

      def trampoline(next: Call): Option[Int] =
        next match {
          case Call.Loop(regexp, index, continuation) =>
            trampoline(loop(regexp, index, continuation))
          case Call.Continue(index, continuation) =>
            trampoline(continuation(index))
          case Call.Done(index) => index
        }

      // Check we matched the entire input
      trampoline(loop(this, 0, opt => Call.Done(opt)))
        .map(idx => idx == input.size)
        .getOrElse(false)
    }

    case Append(left: Regexp, right: Regexp)
    case OrElse(first: Regexp, second: Regexp)
    case Repeat(source: Regexp)
    case Apply(string: String)
    case Empty
  }
  object Regexp extends regexp.RegexpConstructors[Regexp] {
    val empty: Regexp = Empty

    def apply(string: String): Regexp =
      Apply(string)
  }
}
