package regexp

object RegexpDerivUnopt {
  enum Regexp extends regexp.Regexp[Regexp] {
    def ++(that: Regexp): Regexp = {
      Append(this, that)
    }

    def orElse(that: Regexp): Regexp = {
      OrElse(this, that)
    }

    def repeat: Regexp = {
      Repeat(this)
    }

    def `*` : Regexp = this.repeat

    /** True if this regular expression accepts the empty string */
    def nullable: Boolean =
      this match {
        case Append(left, right)   => left.nullable && right.nullable
        case OrElse(first, second) => first.nullable || second.nullable
        case Repeat(source)        => true
        case Apply(string)         => false
        case Epsilon               => true
        case Empty                 => false
      }

    def delta: Regexp =
      if nullable then Epsilon else Empty

    def derivative(ch: Char): Regexp =
      this match {
        case Append(left, right) =>
          (left.derivative(ch) ++ right)
            .orElse(left.delta ++ right.derivative(ch))
        case OrElse(first, second) =>
          first.derivative(ch).orElse(second.derivative(ch))
        case Repeat(source) =>
          source.derivative(ch) ++ this
        case Apply(string) =>
          if string.size == 1 then
            if string.charAt(0) == ch then Epsilon
            else Empty
          else if string.charAt(0) == ch then Apply(string.tail)
          else Empty
        case Epsilon => Empty
        case Empty   => Empty
      }

    def matches(input: String): Boolean = {
      val r = input.foldLeft(this) { (regexp, ch) => regexp.derivative(ch) }
      r.nullable
    }

    case Append(left: Regexp, right: Regexp)
    case OrElse(first: Regexp, second: Regexp)
    case Repeat(source: Regexp)
    case Apply(string: String)
    case Epsilon
    case Empty
  }
  object Regexp extends regexp.RegexpConstructors[Regexp] {
    val empty: Regexp = Empty

    val epsilon: Regexp = Epsilon

    def apply(string: String): Regexp =
      if string.isEmpty() then Epsilon
      else Apply(string)
  }
}
