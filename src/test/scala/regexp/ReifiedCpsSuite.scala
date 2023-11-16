package regexp

import munit.ScalaCheckSuite

class ReifiedCpsSuite extends RegexpSuite(regexp.ReifiedCps.Regexp)
