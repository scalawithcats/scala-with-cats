package regexp

import munit.ScalaCheckSuite

class ReifiedCpsSuite
    extends RegexpSuite(ReifiedCps.Regexp),
      StackSafeSuite(ReifiedCps.Regexp)
