#import "../stdlib.typ": title-page, heading-multiplier, heading-space-base, heading-base

#let parts-and-headings = figure.where(kind: "part", outlined: true).or(heading.where(outlined: true))

// Front matter heading styles
#show heading.where(level: 1): it => {
    // Chapter heading starts on an odd page. Don't create a page break if the
    // page is already empty.
    pagebreak(weak: true, to: "odd")
    set text(size: 24pt * 1.2 * 1.2)
    it
    v(12pt * 1.2 * 1.2)
}
#show heading.where(level: 2): it => {
    v(heading-space-base)
    set text(size: heading-base)
    it
    v(12pt)
}
#show heading.where(level: 3): it => {
    v(12pt / 1.2)
    set text(size: 24pt / 1.2)
    it
    v(12pt)
}
#show heading.where(level: 4): it => {
    v(12pt / 1.2 / 1.2)
    set text(size: 24pt / 1.2 / 1.2)
    it
    v(12pt)
}
// Formatting part entries in the table of contents
#show outline.entry: it => {
  if it.element.func() == figure {
      // // we're configuring part printing here, effectively recreating the default show impl with slight tweaks
      let res =[Part ] + numbering(it.element.numbering, ..it.element.counter.at(it.element.location())) + [: ] + it.element.body

      if it.fill != none {
          res += [ ] + box(width: 1fr, it.fill) + [ ]
      } else {
          res += h(1fr)
      }

      res += it.page()
      link(it.element.location(), res)
  } else {
    // we're doing indenting here
    // h(1em * it.level) + it
      link(
          it.element.location(),
          it.indented(it.prefix(), it.inner()),
      )
  }
}

// Front Matter

// Half Title page
#title-page(half: true)

// Full Title page
#pagebreak(to: "odd")
#title-page(half: false)

// Copyright page
#pagebreak(weak: true, to: "even")
#align(horizon)[
© Copyright 2022--#datetime.today().display("[year]") Noel Welsh.
Licensed under CC BY-SA 4.0

Portions of this work are based on _Scala with Cats_, by Dave
Pereira-Gurnell and Noel Welsh. _Scala with Cats_ is licensed under
CC BY-SA 3.0.

Artwork by Jenny Clements.

#v(2em, weak: true)

Published by Inner Product Consulting Ltd, UK.
]

// Dedication
#pagebreak(to: "odd")
This book is dedicated to those who laid the path that I have followed, to those who will take up where I have left off, and to those who have joined me along the way.

// Table of contents
#pagebreak(to: "odd")
#outline(target: parts-and-headings, depth: 3)

// Preface
#pagebreak(to: "odd")
#set page(numbering: "i")
#set heading(numbering: none)
#include  "../preface/preface.typ"
#include  "../preface/versions.typ"
#include  "../preface/conventions.typ"
#include  "../preface/license.typ"
