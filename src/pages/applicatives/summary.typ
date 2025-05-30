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
Cats provides the `Validated` type
for this specific purpose,
along with apply syntax as
a convenient way to express
the combination of rules.

We have almost covered
all of the functional programming concepts
on our agenda for this book.
The next chapter covers `Traverse` and `Foldable`,
two powerful type classes for converting between data types.
After that we'll look at several case studies
that bring together all of the concepts from Part I.
