#import "../stdlib.typ": info, warning, solution, href
#heading(level: 1, "Preface")


Some twenty years ago I started my first job in the UK.
This job involved a commute by train, giving me about an hour a day to read without distraction.
Around about the same time I first heard about _Structure and Interpretation of Computer Programs_ @sicp:96, referred to as the "wizard book" and spoken of in reverential terms.
It sounded like the just the thing for a recent graduate looking to become a better developer.
I purchased a copy and spent the journey reading it, doing most of the exercises in my head.
_Structure and Interpretation of Computer Programs_ was already an old book at this time, and it's programming style was archaic.
However it's core concepts were timeless and it's fair to say it absolutely blew my mind, putting me on a path I'm still on today.

Another notable stop on this path occured some ten years ago when Dave and I started writing _Scala with Cats_.
In _Scala with Cats_ we attempted to explain the core type classes found in the Cats library, and their use in building software.
I'm proud of the book we wrote together, but time and experience showed that type classes are only a small piece of the puzzle of building software in a functional programming style.
We needed a much wider scope if we were to show people how to effectively build software with all the tools that functional programming provides.
Still, writing a book is a lot of work, and we were busy with other projects, so _Scala with Cats_ remained largely untouched for many years.

Around 2020 I got the itch to return to _Scala with Cats_.
My initial plan was simply to update the book for Scala 3.
Dave was busy with other projects so I decided to go alone.
As the writing got underway I realized I really wanted to cover the additional topics I thought were missing.
If _Scala with Cats_ was a good book, I wanted to aim to write a great book; one that would contain almost everything I had learned about building software.
The title _Scala with Cats_ no longer fit the content, and hence I adopted a new name for what is largely a new book.
The result, _Functional Programming Strategies in Scala with Cats_, is what you are reading now.
I hope you find it useful, and I hope that just maybe some young developer will find this book inspiring the same way I found _Structure and Interpretation of Computer Programs_ inspiring all those years ago.


== Preface from Scala with Cats


The aims of this book are two-fold:
to introduce monads, functors, and other functional programming patterns
as a way to structure program design,
and to explain how these concepts are implemented in #href("https://typelevel.org/cats")[Cats].

Monads, and related concepts, are the functional programming equivalent
of object-oriented design patterns---architectural building blocks
that turn up over and over again in code.
They differ from object-oriented patterns in two main ways:

- they are formally, and thus precisely, defined; and
- they are extremely (extremely) general.

This generality means they can be difficult to understand.
_Everyone_ finds abstraction difficult.
However, it is generality that allows concepts like monads
to be applied in such a wide variety of situations.

In this book we aim to show the concepts in a number of different ways,
to help you build a mental model
of how they work and where they are appropriate.
We have extended case studies, a simple graphical notation,
many smaller examples, and of course the mathematical definitions.
Between them we hope you'll find something that works for you.

Ok, let's get started!
