package regexp

import munit.FunSuite

trait StackSafeSuite[R <: Regexp[R]](
    construct: RegexpConstructors[R]
) extends FunSuite {
  test("Stack safety") {
    val r = construct.apply("a").repeat
    assert(r.matches("a" * 20000))
  }
}
