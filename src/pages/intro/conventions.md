## Conventions Used in This Book {-}

This book contains a lot of technical information and program code.
We use the following typographical conventions
to reduce ambiguity and highlight important concepts:

### Typographical Conventions {-}

New terms and phrases are introduced in *italics*.
After their initial introduction they are written in normal roman font.

Terms from program code, filenames, and file contents,
are written in `monospace font`.
Note that we do not distinguish between singular and plural forms.
For example, we might write `String` or `Strings` to refer to `java.lang.String`.

References to external resources are written as [hyperlinks][link-underscore].
References to API documentation are written
using a combination of hyperlinks and monospace font,
for example: [`scala.Option`][scala.Option].

### Source Code {-}

Source code blocks are written as follows.
Syntax is highlighted appropriately where applicable:

```tut:book:silent
object MyApp extends App {
  println("Hello world!") // Print a fine message to the user!
}
```

Most code passes through [tut][link-tut] to ensure it compiles.
tut uses the Scala console behind the scenes,
so we sometimes show console-style output as comments:

```tut:book
"Hello Cats!".toUpperCase
```

### Callout Boxes {-}

We use two types of *callout box* to highlight particular content:

<div class="callout callout-info">
Tip callouts indicate handy summaries, recipes, or best practices.
</div>

<div class="callout callout-warning">
Advanced callouts provide additional information
on corner cases or underlying mechanisms.
Feel free to skip these on your first read-through---come
back to them later for extra information.
</div>
