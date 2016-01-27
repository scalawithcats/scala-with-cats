## Conventions Used in This Book {-}

This book contains a lot of technical information and program code. We use the following typographical conventions to reduce ambiguity and highlight important concepts:

### Typographical Conventions {-}

New terms and phrases are introduced in *italics*. After their initial introduction they are written in normal roman font.

Terms from program code, filenames, and file contents, are written in `monospace font`. Note that we do not distinguish between singular and plural forms. For example, might write `String` or `Strings` to refer to the `java.util.String` class or objects of that type.

References to external resources are written as [hyperlinks][link-underscore]. References to API documentation are written using a combination of hyperlinks and monospace font, for example: [`scala.Option`][scala.Option].

### Source Code {-}

Source code blocks are written as follows. Syntax is highlighted appropriately where applicable:

```tut:book
object MyApp extends App {
  println("Hello world!") // Print a fine message to the user!
}
```

Some lines of program code are too wide to fit on the page. In these cases we use a *continuation character* (curly arrow) to indicate that longer code should all be written on one line. For example, the following code:

```scala
println("This code should all be written ↩
  on one line.")
```

should actually be written as follows:

```scala
println("This code should all be written on one line.")
```

Most code passes through [tut] to ensure it compiles. To make sure tut works correctly sometimes we wrap code within an object like so:

```tut:book
object example {
  sealed trait Foo[A]
  final case class Bar[A](a: A) extends Foo[A]
  
  println(Bar("wrapping this code in an object makes sure tut interprets it correctly"))
}
```

### Callout Boxes {-}

We use three types of *callout box* to highlight particular content:

<div class="callout callout-info">
Tip callouts indicate handy summaries, recipes, or best practices.
</div>

<div class="callout callout-warning">
Advanced callouts provide additional information on corner cases or underlying mechanisms. Feel free to skip these on your first read-through---come back to them later for extra information.
</div>

<div class="callout callout-danger">
Warning callouts indicate common pitfalls and gotchas. Make sure you read these to avoid problems, and come back to them if you're having trouble getting your code to run.
</div>
