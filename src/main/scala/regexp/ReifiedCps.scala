package regexp

object ReifiedCps {

  type Loop = (Regexp, Int, Continuation) => Option[Int]
  enum Continuation {
    case AppendK(right: Regexp, loop: Loop, next: Continuation)
    case OrElseK(second: Regexp, index: Int, loop: Loop, next: Continuation)
    case RepeatK(regexp: Regexp, index: Int, loop: Loop, next: Continuation)
    case DoneK

    def apply(idx: Option[Int]): Option[Int] =
      this match {
        case AppendK(right, loop, next) =>
          idx match {
            case None    => next(None)
            case Some(i) => loop(right, i, next)
          }

        case OrElseK(second, index, loop, next) =>
          idx match {
            case None => loop(second, index, next)
            case some => next(some)
          }

        case RepeatK(regexp, index, loop, next) =>
          idx match {
            case None    => next(Some(index))
            case Some(i) => loop(regexp, i, next)
          }

        case DoneK =>
          idx
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
      ): Option[Int] =
        regexp match {
          case Append(left, right) =>
            val k: Continuation = AppendK(right, loop, cont)
            loop(left, idx, k)

          case OrElse(first, second) =>
            val k: Continuation = OrElseK(second, idx, loop, cont)
            loop(first, idx, k)

          case Repeat(source) =>
            val k: Continuation = RepeatK(regexp, idx, loop, cont)
            loop(source, idx, k)

          case Apply(string) =>
            cont(Option.when(input.startsWith(string, idx))(idx + string.size))

          case Empty =>
            cont(None)
        }

      // Check we matched the entire input
      loop(this, 0, DoneK)
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
