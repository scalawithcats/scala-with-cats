# Preface {-}

This book in a stop along a journey that started about ten years ago with *Scala with Cats*.
In *Scala with Cats* Dave and I attempted to explain the core type classes found in the Cats library, and their use in building software.
We wrote what I think is a pretty good book, but time and experience showed us that something was lacking.
Type classes are only a small piece of the puzzle of building effective software in a functional programming style.
If we wanted to write a book that laid out what we had learned in over a decade of building software, we needed a much wider scope.
Still, writing a book is a lot of work, and we were busy with other projects, so *Scala with Cats* remained largely untouched.

Around 2020 I got the itch to return to *Scala with Cats*, and add the material that I thought was needed to make it a truly great book.
Dave was busy with other projects so I decided to go alone, building on the foundation of *Scala with Cats* to produce what I hoped would be a truly useful book.
As the writing got underway I realized that the title *Scala with Cats* no longer fit the content, and hence adopted a new name for what is largely a new book.
The result, *Functional Programming Strategies in Scala with Cats*, is what you are reading now.
I hope I've succeeded, and you find reading this book as interesting as I've have found writing it.


## Preface from Scala with Cats {-}

The aims of this book are two-fold:
to introduce monads, functors, and other functional programming patterns
as a way to structure program design,
and to explain how these concepts are implemented in [Cats][link-cats].

Monads, and related concepts, are the functional programming equivalent
of object-oriented design patterns---architectural building blocks
that turn up over and over again in code.
They differ from object-oriented patterns in two main ways:

- they are formally, and thus precisely, defined; and
- they are extremely (extremely) general.

This generality means they can be difficult to understand.
*Everyone* finds abstraction difficult.
However, it is generality that allows concepts like monads
to be applied in such a wide variety of situations.

In this book we aim to show the concepts in a number of different ways,
to help you build a mental model
of how they work and where they are appropriate.
We have extended case studies, a simple graphical notation,
many smaller examples, and of course the mathematical definitions.
Between them we hope you'll find something that works for you.

Ok, let's get started!
