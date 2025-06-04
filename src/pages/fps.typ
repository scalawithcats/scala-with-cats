#import "stdlib.typ": title, authors, heading-multiplier, heading-space-base, heading-base

#set document(
    title: title,
    author: authors
)

// Default styling

#set page(
    paper: "us-trade"
)

#set text(
    font: "EB Garamond 12",
    size: 12pt
)

#set heading(numbering: "1.")

#show raw.where(block: true) :set block(fill: rgb("F7F7F7"), inset: 8pt, width: 100%)
#show link :set text(rgb("#996666"))

// Front matter
#include "parts/frontmatter.typ"

// Main matter
#pagebreak(to: "odd")
#set page(numbering: "1")
#set heading(numbering: "1.")
#counter(page).update(1)
#counter(heading).update(0)

// Intro
#include  "intro/index.typ"
#include  "intro/three-levels.typ"
#include  "intro/what-is-fp.typ"

// The remainder of the main matter is organized into parts
// Offset headings by 1, so that part headings can be level 1 and chapter
// headings are level 2
#set heading(offset: 1)
// Start parts on an odd page
#show <part>: it => {
    pagebreak(weak: true, to: "odd")
    it
}
#show heading.where(level: 1): it => {
    // Part heading starts on an odd page but we insert them based on the label
    set text(size: 24pt * 1.2 * 1.2)
    it
    v(12pt * 1.2 * 1.2)
}
#show heading.where(level: 2): it => {
    // Chapter heading starts on an odd page. Don't create a page break if the
    // page is already empty.
    pagebreak(weak: true, to: "odd")
    set text(size: 24pt * 1.2 * 1.2)
    it
    v(12pt * 1.2 * 1.2)
}
#show heading.where(level: 3): it => {
    v(heading-space-base)
    set text(size: heading-base)
    it
    v(12pt)
}
#show heading.where(level: 4): it => {
    v(12pt / 1.2)
    set text(size: 1.44em / 1.2)
    it
    v(12pt)
}
#show heading.where(level: 5): it => {
    v(12pt / 1.2 / 1.2)
    set text(size: 1.44em / 1.2 / 1.2)
    it
    v(12pt)
}

// Part 1: Foundations
#include  "parts/part1.typ"
// ADTs
#include  "adt/index.typ"
#include  "adt/scala.typ"
#include  "adt/structural-recursion.typ"
#include  "adt/structural-corecursion.typ"
// "adt/applications.typ"
#include  "adt/algebra.typ"
#include  "adt/conclusions.typ"
// Objects as Codata
#include  "codata/index.typ"
// "codata/examples.typ"
#include  "codata/codata.typ"
#include  "codata/scala.typ"
#include  "codata/structural.typ"
#include  "codata/data-codata.typ"
#include  "codata/extensibility.typ"
#include  "codata/exercise.typ"
#include  "codata/conclusions.typ"
// Contextual Abstraction
#include  "type-classes/index.typ"
#include  "type-classes/given.typ"
#include  "type-classes/anatomy.typ"
#include  "type-classes/composition.typ"
#include  "type-classes/what.typ"
#include  "type-classes/display.typ"
#include  "type-classes/instance-selection.typ"
#include  "type-classes/conclusions.typ"
// Interpreters
#include  "adt-interpreters/index.typ"
#include  "adt-interpreters/regexp.typ"
#include  "adt-interpreters/reification.typ"
#include  "adt-interpreters/tail-recursion.typ"
#include  "adt-interpreters/conclusions.typ"
// Part 2: Type Classes
#include  "parts/part2.typ"
// Cats
#include  "cats/index.typ"
#include  "cats/equal.typ"
// Monoid
#include  "monoids/index.typ"
#include  "monoids/cats.typ"
#include  "monoids/applications.typ"
#include  "monoids/summary.typ"
// Functor
#include  "functors/index.typ"
#include  "functors/cats.typ"
#include  "functors/contravariant-invariant.typ"
#include  "functors/contravariant-invariant-cats.typ"
#include  "functors/partial-unification.typ"
#include  "functors/summary.typ"
// Monad
#include  "monads/index.typ"
#include  "monads/cats.typ"
#include  "monads/id.typ"
#include  "monads/either.typ"
#include  "monads/monad-error.typ"
#include  "monads/eval.typ"
#include  "monads/writer.typ"
#include  "monads/reader.typ"
#include  "monads/state.typ"
#include  "monads/custom-instances.typ"
#include  "monads/summary.typ"
#include  "monad-transformers/index.typ"
#include  "monad-transformers/summary.typ"
// Applicative
#include  "applicatives/index.typ"
#include  "applicatives/semigroupal.typ"
#include  "applicatives/examples.typ"
#include  "applicatives/parallel.typ"
#include  "applicatives/applicative.typ"
#include  "applicatives/summary.typ"
// Parallel
// Traverse
#include  "foldable-traverse/index.typ"
#include  "foldable-traverse/foldable.typ"
#include  "foldable-traverse/foldable-cats.typ"
#include  "foldable-traverse/traverse.typ"
#include  "foldable-traverse/traverse-cats.typ"
#include  "foldable-traverse/summary.typ"
// Part 3: Interpreters
#include  "parts/part3.typ"
// Indexed Types
#include  "indexed-types/index.typ"
#include  "indexed-types/phantom-type.typ"
#include  "indexed-types/codata.typ"
#include  "indexed-types/data.typ"
#include  "indexed-types/conclusions.typ"
// Tagless Final
#include  "tagless-final/index.typ"
#include  "tagless-final/codata.typ"
#include  "tagless-final/tagless-final.typ"
#include  "tagless-final/aui.typ"
#include  "tagless-final/tagless-final-dx.typ"
#include  "tagless-final/conclusions.typ"
// Interpreter optimization
#include  "adt-optimization/index.typ"
#include  "adt-optimization/algebra.typ"
#include  "adt-optimization/stack-reify.typ"
#include  "adt-optimization/stack-machine.typ"
// "adt-optimization/effects.typ"
#include  "adt-optimization/conclusions.typ"
// Part 4: Craft
// Part 5: Case Studies
#include  "parts/part4.typ"
#include  "usability/index.typ"
#include  "case-studies/testing/index.typ"
#include  "case-studies/map-reduce/index.typ"
#include  "case-studies/validation/index.typ"
#include  "case-studies/validation/sketch.typ"
#include  "case-studies/validation/check.typ"
#include  "case-studies/validation/map.typ"
#include  "case-studies/validation/kleisli.typ"
#include  "case-studies/validation/conclusions.typ"
#include  "case-studies/crdt/index.typ"
#include  "case-studies/crdt/eventual-consistency.typ"
#include  "case-studies/crdt/g-counter.typ"
#include  "case-studies/crdt/generalisation.typ"
#include  "case-studies/crdt/abstraction.typ"
#include  "case-studies/crdt/summary.typ"

#include  "parts/appendices.typ"
#include  "appendices/solutions.typ"
#include  "appendices/acknowledgements.typ"

#include  "parts/backmatter.typ"
#include  "bibliography.typ"
// #include  "links.typ"
