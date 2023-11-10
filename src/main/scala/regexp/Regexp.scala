package regexp

trait Regexp[R <: Regexp[R]] {
  def ++(that: R): R

  def orElse(that: R): R

  def repeat: R

  def matches(input: String): Boolean
}

trait RegexpConstructors[R <: Regexp[R]] {
  def empty: R
  def apply(string: String): R
}
