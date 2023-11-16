package regexp

object ReifiedCps {

  // Append:
  // - free variables: right: Regexp, cont: Continuation
  // val k: Cont = _ match {
  //   case None    => cont(None)
  //   case Some(i) => loop(right, i, cont)
  // }
  //
  // OrElse
  // - free variables: second: Regexp, idx: Int, cont: Continuation
  // val k: Cont = _ match {
  //   case None => loop(second, idx, cont)
  //   case some => cont(some)
  // }
  //
  // Repeat
  // - free variables: regexp: Regexp, idx: Int, cont: Continuation
  // val k: Cont =
  //   _ match {
  //     case None    => cont(Some(idx))
  //     case Some(i) => loop(regexp, i, cont)
  //   }
  //
  // Apply
  // - free variables: none
  //
  // Empty
  // - free variables: none

  enum Next {
    case Loop(regexp: Regexp, index: Int, continuation: Continuation)
    case Apply(index: Option[Int], continuation: Continuation)
    case Done(index: Option[Int])
  }

  enum Continuation {
    case AppendK(right: Regexp, next: Continuation)
    case OrElseK(second: Regexp, index: Int, next: Continuation)
    case RepeatK(regexp: Regexp, index: Int, next: Continuation)
    case DoneK

    def apply(idx: Option[Int]) =
      this match {
        case AppendK(right, next) =>
          idx match {
            case None    => Next.Apply(None, next)
            case Some(i) => Next.Loop(right, i, next)
          }

        case OrElseK(second, index, next) =>
          idx match {
            case None => Next.Loop(second, index, next)
            case some => Next.Apply(some, next)
          }

        case RepeatK(regexp, index, next) =>
          idx match {
            case None    => Next.Apply(Some(index), next)
            case Some(i) => Next.Loop(regexp, i, next)
          }

        case DoneK =>
          Next.Done(idx)
      }

  }

  enum Regexp extends regexp.Regexp[Regexp] {
    import Continuation.{AppendK, OrElseK, RepeatK, DoneK}

    def ++(that: Regexp): Regexp =
      Append(this, that)

    def orElse(that: Regexp): Regexp =
      OrElse(this, that)

    def repeat: Regexp =
      Repeat(this)

    def `*` : Regexp = this.repeat

    def matches(input: String): Boolean = {
      def loop(
          regexp: Regexp,
          idx: Int,
          cont: Continuation
      ): Next =
        regexp match {
          case Append(left, right) =>
            val k: Continuation = AppendK(right, cont)
            Next.Loop(left, idx, k)

          case OrElse(first, second) =>
            val k: Continuation = OrElseK(second, idx, cont)
            Next.Loop(first, idx, k)

          case Repeat(source) =>
            val k: Continuation = RepeatK(regexp, idx, cont)
            Next.Loop(source, idx, k)

          case Apply(string) =>
            Next.Apply(
              Option.when(input.startsWith(string, idx))(idx + string.size),
              cont
            )

          case Empty =>
            Next.Apply(None, cont)
        }

      def trampoline(next: Next): Option[Int] =
        next match {
          case Next.Loop(regexp, index, continuation) =>
            trampoline(loop(regexp, index, continuation))
          case Next.Apply(index, continuation) =>
            trampoline(continuation(index))
          case Next.Done(index) => index
        }

      // Check we matched the entire input
      trampoline(loop(this, 0, DoneK))
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
