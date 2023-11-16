package regexp

import munit.ScalaCheckSuite

class TrampolinedSuite
    extends RegexpSuite(Trampolined.Regexp),
      StackSafeSuite(Trampolined.Regexp)
