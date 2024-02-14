package set

final class IndicatorSet[A](indicator: A => Boolean, elements: Set[A])
    extends Set[A] {

  def contains(elt: A): Boolean =
    indicator(elt) || elements.contains(elt)

  def insert(elt: A): Set[A] =
    new IndicatorSet(indicator, elements.insert(elt))

  def union(that: Set[A]): Set[A] =
    new IndicatorSet(indicator, that.union(elements))
}
object IndicatorSet {
  def apply[A](f: A => Boolean): Set[A] = new IndicatorSet(f, ListSet.empty)
}
