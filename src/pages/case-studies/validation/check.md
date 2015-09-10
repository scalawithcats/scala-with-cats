## The Check Datatype

Let's start with the basic abstraction. From the description it's fairly obvious
we need to represent "checks" somehow. What should a check be? The simplest
implementation might be a predicate---a function returning a boolean. However
this won't allow us to include a useful error message. We could represent a check as a function that accepts some input of type `A` and returns either an error message or the value `A`. As soon as you see this description you should think of something like

```scala
scala> import scalaz.\/
import scalaz.$bslash$div

scala> object Check {
     |   type Check[A] = A => String \/ A
     | }
defined object Check
```

Here we've represented the error message as a `String`. This is probably not the best representation. We might want to internationalize our error messages, for example, which requires user specific formatting. We could attempt to build some kind of `ErrorMessage` type that holds all the information we can think of. If you find yourself trying to build this kind of type, stop. It's a sign you've gone down the wrong path. If you can't predict the user's requirements don't try. Instead *let them specify what they want*. The way to do this is with a type parameter. Then the user can plug in whatever type they want.

```scala
scala> object Check {
     |   type Check[E,A] = A => E \/ A
     | }
defined object Check
```

We could just run with the declaration above, but we will probably want to add custom methods to `Check` so perhaps we'd better declare a trait instead of a type alias.

```scala
scala> trait Check[E,A] extends Function1[A, E \/ A]
defined trait Check
warning: previously defined object Check is not a companion to trait Check.
Companions must be defined together; you may wish to use :paste mode for this.
```
