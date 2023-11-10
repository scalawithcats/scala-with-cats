package regexp

import munit.ScalaCheckSuite

class ReifiedSuite extends RegexpSuite(regexp.Reified.Regexp)
