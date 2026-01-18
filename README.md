# Functional Programming Strategies in Scala with Cats

The main repository has moved to the [Functional Programming Strategies organization](https://github.com/functionalprogrammingstrategies/functionalprogrammingstrategies) to reflect the change in name. This repository is kept around as an archive of the original Scala with Cats book that gave birth to Functional Programming Strategies.

Copyright [Noel Welsh](http://twitter.com/noelwelsh) 2012-2026.

Artwork by [Jenny Clements](http://patreon.com/miasandelle).

Published by [Inner Product](https://inner-product.com/).

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons Licence" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.

Portions of Functional Programming Strategies in Scala with Cats are based on Scala with Cats by Dave Pereira-Gurnell and Noel Welsh, which is licensed under CC BY-SA 4.0.


## Overview

[Functional Programming Strategies][website] teaches the core concepts and techniques for building practical software in a functional programming style.


## Building

The build requires Scala, Typst, and a few fonts.
There are all installed as part of the 
[CI job that builds the book](https://github.com/scalawithcats/scala-with-cats/blob/develop/.github/workflows/publish.yml).
This is always kept up to date, so refer to it for dependencies and their installation.

Once you have the dependencies installed, run `sbt` to open an SBT prompt.
From within `sbt` you can issue the following commands:

- `build` builds the book, with outuput in `dist/functional-programming-strategies.pdf`


## Contributing

If you spot a typo or mistake,
please feel free to fork the repo and submit a Pull Request.
Add yourself to [acknowledgements.typ](src/pages/appendices/acknowledgements.typ)
to ensure we credit you for your contribution.

If you don't have time to submit a PR
or you'd like to suggest a larger change
to the content or structure of the book,
please raise an issue instead.

[website]: https://functionalprogrammingstrategies.com/
