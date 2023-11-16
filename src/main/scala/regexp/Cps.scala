package regexp

object Cps {
  enum Regexp extends regexp.Regexp[Regexp] {
    def ++(that: Regexp): Regexp =
      Append(this, that)

    def orElse(that: Regexp): Regexp =
      OrElse(this, that)

    def repeat: Regexp =
      Repeat(this)

    def `*` : Regexp = this.repeat

    def matches(input: String): Boolean = {
      // Define a type alias so we can easily write continuations
      type Continuation = Option[Int] => Option[Int]

      def loop(regexp: Regexp, idx: Int, cont: Continuation): Option[Int] =
        regexp match {
          case Append(left, right) =>
            val k: Continuation = _ match {
              case None    => cont(None)
              case Some(i) => loop(right, i, cont)
            }
            loop(left, idx, k)

          case OrElse(first, second) =>
            val k: Continuation = _ match {
              case None => loop(second, idx, cont)
              case some => cont(some)
            }
            loop(first, idx, k)

          case Repeat(source) =>
            val k: Continuation =
              _ match {
                case None    => cont(Some(idx))
                case Some(i) => loop(regexp, i, cont)
              }
            loop(source, idx, k)

          case Apply(string) =>
            cont(Option.when(input.startsWith(string, idx))(idx + string.size))

          case Empty =>
            cont(None)
        }

      // Check we matched the entire input
      loop(this, 0, identity).map(idx => idx == input.size).getOrElse(false)
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
