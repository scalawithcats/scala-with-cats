enum Regexp {
  def ++(that: Regexp): Regexp =
    Append(this, that)

  def orElse(that: Regexp): Regexp =
    OrElse(this, that)

  def repeat: Regexp =
    Repeat(this)

  def `*` : Regexp = this.repeat

  def matches(input: String): Boolean = {
    enum Resumable {
      case Done(result: Option[Int])
      case Resume(cont: () => Resumable)
    }
    // Define a type alias so we can easily write continuations
    type Cont = Option[Int] => Resumable

    def loop(
        regexp: Regexp,
        idx: Int,
        cont: Option[Int] => Resumable
    ): Resumable =
      regexp match {
        case Append(left, right) =>
          val k: Cont = _ match {
            case None    => cont(None)
            case Some(i) => loop(right, i, cont)
          }
          Resumable.Resume(() => loop(left, idx, k))

        case OrElse(first, second) =>
          val k: Cont = _ match {
            case None => loop(second, idx, cont)
            case some => cont(some)
          }
          Resumable.Resume(() => loop(first, idx, k))

        case Repeat(source) =>
          val k: Cont =
            _ match {
              case None    => cont(Some(idx))
              case Some(i) => loop(regexp, i, cont)
            }
          Resumable.Resume(() => loop(source, idx, k))

        case Apply(string) =>
          Resumable.Resume(() =>
            cont(Option.when(input.startsWith(string, idx))(idx + string.size))
          )
      }

    def trampoline(cont: Resumable): Option[Int] =
      cont match {
        case Resumable.Done(result) => result
        case Resumable.Resume(cont) => trampoline(cont())
      }

    // Check we matched the entire input
    trampoline(loop(this, 0, opt => Resumable.Done(opt)))
      .map(idx => idx == input.size)
      .getOrElse(false)
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
