package stream

import munit.ScalaCheckSuite
import org.scalacheck.Gen
import org.scalacheck.Prop.*

class StreamSuite extends ScalaCheckSuite {
  property("ones is all one") {
    forAll(Gen.posNum[Int]) { size =>
      assertEquals(Stream.ones.take(size), List.fill(size)(1))
    }
  }

  property("map does map") {
    forAll(Gen.posNum[Int], Gen.posNum[Int]) { (size, increment) =>
      val f: Int => Int = x => x + increment
      assertEquals(
        Stream.ones.map(f).take(size),
        List.fill(size)(1).map(f)
      )
    }
  }

  property("zip does zip") {
    val f: Int => Int = x => x + 3
    forAll(Gen.posNum[Int]) { size =>
      assertEquals(
        Stream.ones.zip(Stream.ones.map(f)).take(size),
        List.fill(size)(1).map(x => (x, x + 3))
      )
    }
  }

  property("scan produces partial results") {
    val naturals = Stream.ones.scan(0)(_ + _)
    forAll(Gen.posNum[Int]) { size =>
      assertEquals(naturals.take(size), List.iterate(1, size)(x => x + 1))
    }
  }
}
