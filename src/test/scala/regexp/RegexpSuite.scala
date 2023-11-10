package regexp

import munit.ScalaCheckSuite
import org.scalacheck.Gen
import org.scalacheck.Prop.*

trait RegexpSuite[R <: Regexp[R]](
    construct: RegexpConstructors[R]
) extends ScalaCheckSuite {
  val nonEmptyAlphaNumStr =
    Gen.posNum[Int].flatMap(n => Gen.stringOfN(n, Gen.alphaNumChar))

  test("empty string matches only empty string") {
    val r = construct.apply("")
    assert(r.matches(""))
    assert(!r.matches("a"))
    assert(!r.matches("ab"))
    assert(!r.matches("abc"))
  }

  property("non-empty string matches only given input string") {
    forAll(nonEmptyAlphaNumStr, nonEmptyAlphaNumStr) {
      (input: String, junk: String) =>
        val r = construct.apply(input)
        assert(r.matches(input))
        assert(!r.matches(input ++ junk))
        assert(!r.matches(input.drop(1)))
    }
  }

  property("append matches both strings in order") {
    forAll(nonEmptyAlphaNumStr, nonEmptyAlphaNumStr) {
      (first: String, second: String) =>
        val r = construct.apply(first) ++ construct.apply(second)
        assert(r.matches(first ++ second))
        assert(!r.matches(first))
        assert(!r.matches(second))
        assert(!r.matches(first ++ second ++ ":-)"))
        if (first != second) then assert(!r.matches(second ++ first))
    }
  }

  property("orElse matches first or second") {
    forAll(nonEmptyAlphaNumStr, nonEmptyAlphaNumStr) {
      (first: String, second: String) =>
        val r = construct.apply(first).orElse(construct.apply(second))
        assert(r.matches(first))
        assert(r.matches(second))
        assert(!r.matches(first ++ second))
    }
  }

  property("repeat matches zero or more times") {
    forAll(nonEmptyAlphaNumStr, Gen.posNum[Int]) { (string: String, n: Int) =>
      val r = construct.apply(string).repeat
      assert(r.matches(""))
      assert(r.matches(string))
      assert(r.matches(string * n))
      assert(!r.matches(string ++ ":-)"))
    }
  }

  property("empty does not match any string") {
    val r = construct.empty

    forAll(nonEmptyAlphaNumStr) { (string: String) =>
      assert(!r.matches(string))
    }
  }

  test("Sca(la)* matches as expected") {
    val r = construct.apply("Sca") ++ construct
      .apply("la") ++ construct.apply("la").repeat

    assert(r.matches("Scala"))
    assert(r.matches("Scalalalala"))

    assert(!r.matches("Sca"))
    assert(!r.matches("Scalal"))
    assert(!r.matches("Scalaland"))
  }

}
