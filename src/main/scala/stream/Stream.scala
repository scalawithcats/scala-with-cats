package stream

trait Stream[A] {
  def head: A
  def tail: Stream[A]

  def map[B](f: A => B): Stream[B] = {
    val self = this
    new Stream[B] {
      def head: B = f(self.head)
      def tail: Stream[B] = self.tail.map(f)
    }
  }

  def scan[B](zero: B)(f: (B, A) => B): Stream[B] = {
    val self = this
    new Stream[B] {
      def head: B = f(zero, self.head)
      def tail: Stream[B] = self.tail.scan(head)(f)
    }
  }

  def zip[B](that: Stream[B]): Stream[(A, B)] = {
    val self = this
    new Stream[(A, B)] {
      def head: (A, B) =
        (self.head, that.head)

      def tail: Stream[(A, B)] =
        self.tail.zip(that.tail)
    }
  }

  def take(count: Int): List[A] =
    count match {
      case 0 => List.empty
      case n => head :: tail.take(n - 1)
    }
}
object Stream {
  val ones: Stream[Int] =
    new Stream[Int] {
      def head: Int = 1

      def tail: Stream[Int] = ones
    }

  val naturals: Stream[Int] =
    ones.scan(0)(_ + _)

  def unfold[S, A](): Stream[A] =
    ???
}
