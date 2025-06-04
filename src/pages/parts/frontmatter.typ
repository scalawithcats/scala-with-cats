#import "../stdlib.typ": title-page, heading-multiplier, heading-space-base, heading-base

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
// Front Matter

// Half Title page
#title-page(half: true)

// Full Title page
#pagebreak(to: "odd")
#title-page(half: false)


// Dedication
#pagebreak(to: "odd")
This book is dedicated to those who laid the path that I have followed, to those who will take up where I have left off, and to those who have joined me along the way.

// Table of contents
#pagebreak(to: "odd")
#outline(depth: 3)

// Preface
#pagebreak(to: "odd")
#set page(numbering: "i")
#set heading(numbering: none)
#include  "../preface/preface.typ"
#include  "../preface/versions.typ"
#include  "../preface/conventions.typ"
#include  "../preface/license.typ"
