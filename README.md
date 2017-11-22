# Scala with Cats

Copyright [Noel Welsh](http://twitter.com/noelwelsh)
and [Dave Gurnell](http://twitter.com/davegurnell), 2014-2017.

Artwork by [Jenny Clements](http://patreon.com/miasandelle).

Published by [Underscore Consulting LLP](http://underscore.io).

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons Licence" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.

## Overview

[Scala with Cats][scala-with-cats] teaches
core functional abstractions of monoids, functors, monads, and applicative functors
using the [Cats](http://typelevel.org/cats) library and a number of case studies.

## Building

Scala with Cats uses [Underscore's ebook build system][ebook-template].

The simplest way to build the book is to use [Docker Compose](http://docker.com):

- install Docker Compose (`brew install docker-compose` on OS X;
  or download from [docker.com](http://docker.com/)); and

- run `go.sh` (or `docker-compose run book bash` if `go.sh` doesn't work).

This will open a `bash` shell running inside the Docker container
that contains all the dependencies to build the book.
From the shell run:

- `npm install`; and then
- `sbt`.

Within `sbt` you can issue the commands
`pdf`, `html`, `epub`, or `all`
to build the desired version(s) of the book.
Targets are placed in the `dist` directory.

## Contributing

If you spot a typo or mistake,
please feel free to fork the repo and submit a Pull Request.
Add yourself to `src/pages/contributors.md`
to ensure we credit you for your contribution.

If you don't have time to submit a PR
or you'd like to suggest a larger change
to the content or structure of the book,
please raise an issue instead.

[ebook-template]: https://github.com/underscoreio/underscore-ebook-template
[scala-with-cats]: https://underscore.io/books/scala-with-cats
