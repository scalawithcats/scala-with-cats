#import "../stdlib.typ": info, warning, solution
== Summary


While monads and functors are the most widely used
sequencing data types we've covered in this book,
semigroupals and applicatives are the most general.
These type classes provide a generic mechanism
to combine values and apply functions within a context,
from which we can fashion monads and a variety of other combinators.

`Semigroupal` and `Applicative` are
most commonly used as a means of
combining independent values such as
the results of validation rules.
Cats provides the `Parallel` type class
to allow to easily switch between a monad and
an alternative applicative (or semigroupal) semantics.

Applicative and semigroupal are both introduced in
#narrative-cite(<mcbride08:applicative>)#footnote[Semigroupal is referred to as "monoidal" in the paper.].
