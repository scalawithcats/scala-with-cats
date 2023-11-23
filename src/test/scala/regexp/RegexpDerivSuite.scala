package regexp

import munit.ScalaCheckSuite

class RegexpDerivSuite extends RegexpSuite(RegexpDeriv.Regexp) {
  test("True alternation") {
    val r = construct.apply("z").orElse(construct.apply("zabc"))
    assert(r.matches("z"))
    assert(r.matches("zabc"))
  }
}
