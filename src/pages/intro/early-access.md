## Notes on the Early Access Edition {-}

<div class="callout callout-danger">
This book is in *early access* status.
This means there are unfinished aspects as detailed below.
There may be typos and errata in the text and examples.
If you spot any mistakes
or would like to provide feedback on the book,
please let us know on Github:

[https://github.com/underscoreio/advanced-scala][link-github]

---Dave and Noel
</div>

### Changelog {-}

Starting from the March 2016 release, here are the major changes to the book:

- Moved the theoretical chapters from Scalaz to Cats (currently version `0.7.2`).
- Added sections on the `Reader`, `Writer`, `State`, and `Eval` monads.
- Added a chapter on monad transformers.
- Added sections on `Semigroupal` to the applicatives chapter.
- Added sections on `Foldable` and `Traverse`.
- Added type chart diagrams for `Functor` and `Monad`.
- Added a new case study on asynchonous testing.
- New diagrams for the map reduce and validation case studies.
- Upgraded to Cats 0.9.1
- Upgraded to Cats 1.0.0-MF:
   - Replaced the section on semigroupal builder syntax
     with a section on apply syntax.
   - Removed the section on `Unapply`.
   - Added a section on `-Ypartial-unification`.
- Added a list of contributors to the Intro
- Added a list of backers to the Intro
- Upgraded to Cats 1.0.0-RC1:
  - Renamed `Cartesian` to `Semigroupal`
  - Removed references to `Foldable` for `Map` (now in Alleycats)

### Omissions {-}

Here are the major things missing from the book:

 1. Incorporate all the feedback from Github Issues.
 2. Proof reading, final tweaks.
