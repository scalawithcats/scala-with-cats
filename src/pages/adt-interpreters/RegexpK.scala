enum Regexp {
  def ++(that: Regexp): Regexp =
    Append(this, that)

  def orElse(that: Regexp): Regexp =
    OrElse(this, that)

  def repeat: Regexp =
    Repeat(this)

  def `*` : Regexp = this.repeat

  def matches(input: String): Boolean = {
    // Define a type alias so we can easily write continuations
    type Cont = Option[Int] => Option[Int]

    def loop(
        regexp: Regexp,
        idx: Int,
        cont: Option[Int] => Option[Int]
    ): Option[Int] =
      regexp match {
        case Append(left, right) =>
          val k: Cont = _.flatMap(i => loop(right, i, cont))
          loop(left, idx, k)

        case OrElse(first, second) =>
          val k: Cont = _.orElse(loop(second, idx, cont))
          loop(first, idx, k)

        case Repeat(source) =>
          val k: Cont =
            _.map(i => loop(regexp, i, cont).getOrElse(i)).orElse(Some(idx))
          loop(source, idx, k)

        case Apply(string) =>
          cont(Option.when(input.startsWith(string, idx))(idx + string.size))
      }

    // Check we matched the entire input
    loop(this, 0, identity).map(idx => idx == input.size).getOrElse(false)
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
}
object Regexp {
  def apply(string: String): Regexp =
    Apply(string)
}

val regexp = Regexp("Sca") ++ Regexp("la") ++ Regexp("la").repeat
regexp.matches("Scala")
regexp.matches("Scalalalala")
regexp.matches("Sca")
regexp.matches("Scalal")
