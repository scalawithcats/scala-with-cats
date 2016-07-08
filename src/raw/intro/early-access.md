## Notes on the Pre-Release Edition {-}

<div class="callout callout-danger">
This book is in *early access* status.
This means there are unfinished aspects as detailed below.
There may be typos and errata in the text and examples.

As an early access customer you will receive a
**free copy of the final text** when it is released,
plus **free lifetime updates**.
If you spot any mistakes or would like to provide feedback on the book,
please let us know!

---Dave Gurnell ( [dave@underscore.io](mailto:dave@underscore.io) )
and Noel Welsh ( [noel@underscore.io](mailto:noel@underscore.io) ).
</div>

### Changelog {-}

Starting from the March 2016 release, here are the major changes to the book:

- Moved the theoretical chapters from Scalaz to Cats (currently version `0.7.0-SNAPSHOT`).

- Added sections on the `Reader`, `Writer`, `State`, and `Eval` monads.

- Added a chapter on monad transformers.

- Added sections on `Cartesian` to the applicatives chapter.

### Omissions {-}

Here are the major things missing from the book:

1. We need to add chapters/sections on `Kleisli`, `Traverse`, invariant, and contravariant functors.

2. Many chapters are missing introductory narrative to introduce general concepts before we get into technical detail.

3. We've had great experience in the classroom using graphical notation to describe the various sequencing type classes. We will add these diagrams (and corresponding narrative) to the chapters on functors, monads, cartesians, and applicatives.

4.  We are missing a few summary chapters. These include a condensed discussion of the concepts we've covered in the book.

5.  We are missing some of the case studies that make up the last third of the book. These are in various states of completion so we have chosen to hold them back until we have a better idea of what they will look like. Some case studies are still written using Scalaz.
