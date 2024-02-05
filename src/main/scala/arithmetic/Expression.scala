package arithmetic

trait Expression[E <: Expression[E]] {
  def +(that: E): E
  def *(that: E): E
  def -(that: E): E
  def /(that: E): E
}
trait ExpressionConstructors[E <: Expression[E]] {
  def literal(value: Double): E
}
