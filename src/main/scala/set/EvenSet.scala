package set

final class EvenSet(elements: Set[Int]) extends Set[Int] {

  def contains(elt: Int): Boolean =
    (elt % 2 == 0) || elements.contains(elt)

  def insert(elt: Int): Set[Int] =
    EvenSet(elements.insert(elt))

  def union(that: Set[Int]): Set[Int] =
    EvenSet(that.union(elements))
}
object EvenSet {
  val evens: Set[Int] = EvenSet(ListSet.empty)
}
