#import "../stdlib.typ": info, warning, solution
== Indexed Codata


The basic idea of indexed codata is to prevent methods being called unless certain conditions, encoded in types, are met. More precisely, methods are guarded by type equalities that callers must prove they satisfy to call a method. The contextual abstraction features, `given` instances and `using` clauses, are used to implement this in Scala.

We'll start our exploration of indexed codata with a very simple example.
We are going to define a switch that can only be turned on when it is off, and off when it is on.
Since this is codata, we start with an interface.

```scala mdoc:silent
trait Switch {
  def on: Switch
  def off: Switch
}
```

There are no constraints on this interface as defined; we can turn any switch on, even if it is already on, and vice versa.
The first step to implement such a constraint is to add a type parameter, which will hold the state of the `Switch`.
This type parameter doesn't correspond to any data we store in `Switch`, so it is a phantom type.

```scala mdoc:reset:silent
trait Switch[A] {
  def on: Switch[A]
  def off: Switch[A]
}
```

We are now going to add constraints that say we can only call certain methods when this type parameter corresponds to particular concrete types.
It is in this way that indexed codata goes beyond what phantom types alone can do: we can inspect, at compile-time, the type of a type parameter and make decisions based on this type.

Implementing these constraints has two parts.
The first is defining types to represent on and off. 

```scala mdoc:reset:silent
trait On
trait Off
```

The second step is to add the constraints to the relevant methods on `Switch`.
Here is how we do it.

```scala mdoc:silent
trait Switch[A] {
  def on(using ev: A =:= Off): Switch[On]
  def off(using ev: A =:= On): Switch[Off]
}
```

We can create an implementation to show it really works.

```scala mdoc:silent
final case class SimpleSwitch[A]() extends Switch[A] {
  def on(using ev: A =:= Off): Switch[On] =
    SimpleSwitch()
  def off(using ev: A =:= On): Switch[Off] =
    SimpleSwitch()
}
object SimpleSwitch {
  val on: Switch[On] = SimpleSwitch()
  val off: Switch[Off] = SimpleSwitch()
}
```

Here are some examples of using it correctly

```scala mdoc
SimpleSwitch.on.off
SimpleSwitch.off.on
```

Incorrect uses fail to compile.

```scala mdoc:fail
SimpleSwitch.on.on
```

The constraint is made of two parts: using clauses, which we learned about in @sec:type-classes, and the [`A =:= B`][scala.=:=] construction, which is new. `=:=` represents a type equality. If a given instance `A =:= B` exists, then the type `A` is equal to the type `B`. (Note we can write this with the more familiar prefix notation `=:=[A, B]` if we prefer.) We never create these instances ourselves; instead the compiler creates them for us. In the method `on` we are asking the compiler to construct an instance `A =:= Off`, which can only be done if `A` _is_ `Off`. This in turn means we can only call the method when the `Switch` is `Off`. This is the core idea of indexed codata: we raise states into types, and restrict method calls to a subset of states.

This is a different use of contextual abstraction to type classes. 
Type classes associate operations with types.
What we're doing here is proving some property of a type with respect to another type.
More precisely we're proving that a type parameter is equal to a particular type.
The given instance only exists when the compiler can prove this is the case.
Hence these given instances are sometimes called *evidence* or *witnesses*.
This different view subsumes type classes, 
as we can think of type classes as evidence that a type implements a certain interface.


==== Exercise: Torque {-}


In @sec:indexed-types:phantom we saw we could use phantom types to represent units.
We also ran into a limitation: we had no way to inspect the phantom types and hence make decisions based on them.
Now, with indexed codata, we can do solve this problem.

Below if the definition of `Length` we previously used. Your mission is to:

+ implement a type `Force`, parameterized by a phantom type that represents the units of force;
+ implement a type `Torque`, parameterized by a phantom type that represents the units of torque;
+ define types `Newtons` and `NewtonMetres` to represent force in SI units;
+ implement a method `*` on `Force` that accepts a `Length` and returns a `Torque`. It can only be called if the `Force` is in `Newtons` and the `Length` is in `Metres`. In this case the `Torque` is in `NewtonMetres`. (Torque is force times length.)

```scala mdoc:silent
final case class Length[Unit](value: Double) {
  def +(that: Length[Unit]): Length[Unit] =
    Length[Unit](this.value + that.value)
}
```

#solution[
Defining `Force`, `Torque`, and the unit types is a repeat of the pattern we saw in the example code.

```scala mdoc:silent
trait Newtons
trait NewtonMetres

final case class Force[Unit](value: Double)
final case class Torque[Unit](value: Double)
```

To define the `*` method on `Force` we need constraints that specify `Force's` `Unit` type is `Newtons`, and `Length's` `Unit` type is `Metres`. These are both type equalities, so we can express them with `=:=`.

```scala mdoc:reset:invisible
trait Metres
trait Feet
trait Newtons
trait NewtonMetres

final case class Length[Unit](value: Double) {
  def +(that: Length[Unit]): Length[Unit] =
    Length[Unit](this.value + that.value)
}
final case class Torque[Unit](value: Double)
```

```scala mdoc:silent
final case class Force[Unit](value: Double) {
  def *[L](length: Length[L])(using Unit =:= Newtons, L =:= Metres): Torque[NewtonMetres] =
    Torque(this.value * length.value)
}
```
]


=== API Protocols


An API protocol defines the order in which methods must be called. The protocol in the case of `Switch` is that we can only call `off` after calling `on` and vice versa. This protocol is a simple finite state machine, and illustrated in @fig:indexed-types:switch. Many common types have similar protocols. For example, files can only be read once they are opened and cannot be read once they have been closed.

#figure(image("switch.svg"), caption: [The switch API protocol])
<fig:indexed-types:switch>

Indexed codata allows us to enforce API protocols at compile-time. Often these protocols are finite-state machines. We can represent these protocols with a single type parameter that represents the state, as we did with `Switch`. We can also use multiple type parameters if that makes for a more convenient representation. 

Let's see an example using multiple type parameters. We're going to build an API that represents a very limited subset of [HTML][html], the language the defines web pages. An example of HTML is below.

```html
<!DOCTYPE html>
<html>
  <head><title>Our Amazing Web Page</title></head>
  <body>
    <h1>This Is Our Amazing Web Page</h1>
    <p>Please be in awe of its <strong>amazingness</strong></p>
  </body>
</html>
```

In HTML the content of the page is marked up with tags, like `<h1>`, that give it meaning. 
For example, `<h1>` means a heading at level one, and `<p>` means a paragraph.
An opening tag is closed by a corresponding closing tag, such as `</h1>` for `<h1>` and `</p>` for `<p>`.

There are several rules for valid HTML[^valid-html]. We're going to focus on the following:

+ Within the `html` tag there can only be a `head` and a `body` tag, in that order.
+ Within the `head` tag there must be exactly one `title`, and there can be any other number of allowed tags (of which we're only going to model `link`).
+ Within the `body` there can be any number of allowed tags (of which we are only going to model `h1` and `p`).

We're going to use a Church-encoded representation for HTML, so tags are created by method calls. @fig:indexed-types:html shows the finite state machine representation of the API protocol.
I find it easier to read as a regular expression, which we can write down as

$
"head" "link" "title" "link" "body" ("h1" | "p")^*
$

#figure(image("html.svg"), caption: [The HTML API protocol])
<fig:indexed-types:html>

As the code is fairly repetitive I will just present all the code and then discuss the important parts.
Here's the implementation.

```scala mdoc:silent
sealed trait StructureState
trait Empty extends StructureState
trait InHead extends StructureState
trait InBody extends StructureState

sealed trait TitleState
trait WithoutTitle extends TitleState
trait WithTitle extends TitleState

// Not a case class so external users cannot copy it
// and break invariants
final class Html[S <: StructureState, T <: TitleState](
    head: Vector[String],
    body: Vector[String]
) {
  // Head tags ---------------------------------------------

  def head(using S =:= Empty): Html[InHead, WithoutTitle] =
    Html(head, body)

  def title(
      text: String
  )(using S =:= InHead, T =:= WithoutTitle): Html[InHead, WithTitle] =
    Html(head :+ s"<title>$text</title>", this.body)

  def link(rel: String, href: String)(using S =:= InHead): Html[InHead, T] =
    Html(head :+ s"<link rel=\"$rel\" href=\"$href\"/>", body)

  // Body tags ---------------------------------------------

  def body(using S =:= InHead, T =:= WithTitle): Html[InBody, WithTitle] =
    Html(head, body)

  def h1(text: String)(using S =:= InBody): Html[InBody, T] =
    Html(head, body :+ s"<h1>$text</h1>")

  def p(text: String)(using S =:= InBody): Html[InBody, T] =
    Html(head, body :+ s"<p>$text</p>")

  // Interpreter ------------------------------------------

  override def toString(): String = {
    val h = head.mkString("  <head>\n    ", "\n    ", "\n  </head>")
    val b = body.mkString("  <body>\n    ", "\n    ", "\n  </body>")

    s"\n<html>\n$h\n$b\n</html>"
  }
}
object Html {
  val empty: Html[Empty, WithoutTitle] = Html(Vector.empty, Vector.empty)
}
```

The key point is that we factor the state into two components.
`StructureState` represents where in the overall structure we are (inside the `head`, inside the `body`, or inside neither).
`TitleState` represents the state when defining the elements inside the `head`, specifically whether we have a `title` element or not.
We could certainly represent this with one state type variable, but I find the factored representation both easier to work with and easier for other developers to understand.

Here's an example in use.

```scala mdoc
Html.empty.head
  .link("stylesheet", "styles.css")
  .title("Our Amazing Webpage")
  .body
  .h1("Where Amazing Exists")
  .p("Right here")
  .toString
```

Here's an example of the type system preventing an invalid construction, in this case the lack of a title.

```scala mdoc:fail
Html.empty.head
  .link("stylesheet", "styles.css")
  .body
  .h1("This Shouldn't Work")
```

These error messages are not great. We'll address this in @sec:usability.

We can implement more complex protocols, such as those that can be represented by context-free or even context-sensitive grammars, using the same technique.


==== Exercise: HTML API Design {-}


I don't particularly like the HTML API we developed above, 
as the flat method call structure doesn't match the nesting in the HTML structure we're creating.
I would prefer to write the following.

```scala 
Html.empty
  .head(_.title("Our Amazing Webpage"))
  .body(_.h1("Where Amazing Happens").p("Right here"))
  .toString
```

We still require the `head` is specified before the `body`, 
but now the nesting of the method calls matches the nesting of the structure.
Notice we're still using a Church-encoded representation.

Can you think of how to implement this? 
You'll need to use indexed codata, and perhaps a bit of inspiration.
This is a very open ended question, so don't worry if you struggle with it!

#solution[
Here's how I implemented it.
The structure is very similar to the original implementation,
but where we factored the state into type parameters 
I also factored the implementation into types.
Notice how we use `Head` and `Body` to accumulate the set of tags that make up the head and body respectively.
We still need to use indexed codata in some place, but we can avoid it in others.
For example, the `head` method simply requires a function of type `Head[WithoutTitle] => Head[WithTitle]`.

```scala mdoc:reset:silent
sealed trait StructureState
trait NeedsHead extends StructureState
trait NeedsBody extends StructureState
trait Complete extends StructureState

sealed trait TitleState
trait WithoutTitle extends TitleState
trait WithTitle extends TitleState

final class Head[S <: TitleState](contents: Vector[String]) {
  def title(text: String)(using S =:= WithoutTitle): Head[WithTitle] =
    Head(contents :+ s"<title>$text</title>")

  def link(rel: String, href: String): Head[S] =
    Head(contents :+ s"<link rel=\"$rel\" href=\"$href\"/>")

  override def toString(): String =
    contents.mkString("  <head>\n    ", "\n    ", "\n  </head>")
}
object Head {
  val empty: Head[WithoutTitle] = Head(Vector.empty)
}

final class Body(contents: Vector[String]) {
  def h1(text: String): Body =
    Body(contents :+ s"<h1>$text</h1>")

  def p(text: String): Body =
    Body(contents :+ s"<p>$text</p>")

  override def toString(): String =
    contents.mkString("  <body>\n    ", "\n    ", "\n  </body>")
}
object Body {
  val empty: Body = Body(Vector.empty)
}

final class Html[S <: StructureState](
    head: Head[?],
    body: Body
) {
  def head(f: Head[WithoutTitle] => Head[WithTitle])(using
      S =:= NeedsHead
  ): Html[NeedsBody] =
    Html(f(Head.empty), body)

  def body(f: Body => Body)(using S =:= NeedsBody): Html[Complete] =
    Html(head, f(Body.empty))

  override def toString(): String = {
    s"\n<html>\n${head.toString()}\n${body.toString()}\n</html>"

  }
}
object Html {
  val empty: Html[NeedsHead] = Html(Head.empty, Body.empty)
}
```

As always, we should show that is works.
Here's the output from the motivating example.

```scala mdoc
Html.empty
  .head(_.title("Our Amazing Webpage"))
  .body(_.h1("Where Amazing Happens").p("Right here"))
  .toString()
```
]

[html]: https://html.spec.whatwg.org/multipage/

[^valid-html]: The HTML specification allows for very lenient parsing of HTML. For example, if we don't define the `head` tag it will usually be inferred. However we aren't going to allow that kind of leniency in our API.


=== Beyond Equality Constraints


Indexed data is all about equality constraints: proofs that some type parameter is equal to some type.
However we can go beyond equality constraints with contextual abstraction.
We can use [`<:<`][scala.<:<] for evidence of a subtyping relationship, 
and [`NotGiven`][scala.NotGiven] for evidence that no given instance exists (with which we can test that types are not equal, for example).
Beyond that, we can view any given instance as evidence.

Let's return to our example of length, force, and torque to see how this is useful.
In the exercise where we defined torque as force times length, we fixed the computation to have SI units.
The example code is below.

```scala
final case class Force[Unit](value: Double) {
  def *[L](length: Length[L])(using Unit =:= Newtons, L =:= Metres): Torque[NewtonMetres] =
    Torque(this.value * length.value)
}
```

This is a reasonable thing to do, as other units are insane, but there are a lot of insane people out there.
To accommodate other unit types we can create given instances that represent the result types of operations of interest.
In this case we want to represent the result of multiplying a length unit by the force unit.
In code we can write the following.

```scala mdoc:reset:invisible
trait Metres
trait Newtons
trait NewtonMetres

final case class Torque[Unit](value: Double)
```
```scala mdoc:silent
// Weird units
trait Feet
trait Pounds
trait PoundsFeet

// An instance exists if A * B = C
trait Multiply[A, B, C]
object Multiply {
  given Multiply[Metres, Newtons, NewtonMetres] = new Multiply {}
  given Multiply[Feet, Pounds, PoundsFeet] = new Multiply {}
}
```

Now we can define `*` methods on `Length` and `Force` in terms of `Multiply`.

```scala mdoc:silent
final case class Length[L](value: Double) {
  def *[F, T](that: Force[F])(using Multiply[L, F, T]): Torque[T] =
    Torque(this.value * that.value)
}

final case class Force[F](value: Double) {
  def *[L, T](that: Length[L])(using Multiply[F, L, T]): Torque[T] =
    Torque(this.value * that.value)
}
```

Here's an example showing it works. 

```scala mdoc
Length[Metres](3) * Force[Newtons](4)

Length[Feet](3) * Force[Pounds](4)
```

Note that's it hard to think of `Multiply` as a type class, as it does not provide _any_ methods.
Viewing it as evidence, however, does make sense.


==== Exercise: Commutivitiy {-}


In the example above we defined a `Multiply` type class to represent that metres times newtons gives newton metres.
Multiplication is commutative. If $A times B = C$, then $B times A = C$.
However we have not represented this, and if we try newtons times metres, as in the example below, the code will fail.

```scala mdoc:fail
Force[Newtons](3) * Length[Metres](4)
```

Add evidence to `Multiply` that if `Multiply[A, B, C]` exists, then so does `Multiply[B, A, C]`, and show that it solves this problem.


#solution[
```scala mdoc:reset:invisible
trait Metres
trait Newtons
trait NewtonMetres

final case class Torque[Unit](value: Double)
```

To solve this I defined a given instance called `commutative`, as shown below.

```scala mdoc:silent
// An instance exists if A * B = C
trait Multiply[A, B, C]
object Multiply {
  given Multiply[Metres, Newtons, NewtonMetres] = new Multiply {}
  
  // A * B == B * A
  given commutative[A, B, C](using Multiply[A, B, C]): Multiply[B, A, C] =
    new Multiply {}
}
```
```scala mdoc:invisible
final case class Length[L](value: Double) {
  def *[F, T](that: Force[F])(using Multiply[L, F, T]): Torque[T] =
    Torque(this.value * that.value)
}

final case class Force[F](value: Double) {
  def *[L, T](that: Length[L])(using Multiply[F, L, T]): Torque[T] =
    Torque(this.value * that.value)
}
```

Now the example works as expected.

```scala mdoc
Force[Newtons](3) * Length[Metres](4)
```
]

Now that we have learned about indexed codata, we'll turn to its dual, indexed data.
