#import "../stdlib.typ": info, warning, solution
= Semigroupal and Applicative 
<sec:applicatives>


In previous chapters we saw
how functors and monads let us
sequence operations using `map` and `flatMap`.
While functors and monads are
both immensely useful abstractions,
there are certain types of program flow
that they cannot represent.

One such example is form validation.
When we validate a form we want to
return _all_ the errors to the user,
not stop on the first error we encounter.
If we model this with a monad like `Either`,
we fail fast and lose errors.
For example, the code below
fails on the first call to `parseInt`
and doesn't go any further:

```scala mdoc:silent
import cats.syntax.either.* // for catchOnly

def parseInt(str: String): Either[String, Int] =
  Either.catchOnly[NumberFormatException](str.toInt).
    leftMap(_ => s"Couldn't read $str")
```

```scala mdoc
for {
  a <- parseInt("a")
  b <- parseInt("b")
  c <- parseInt("c")
} yield (a + b + c)
```

Another example is the concurrent evaluation of `Futures`.
If we have several long-running independent tasks,
it makes sense to execute them concurrently.
However, monadic comprehension
only allows us to run them in sequence.
`map` and `flatMap` aren't quite capable
of capturing what we want because
they make the assumption that each computation
is _dependent_ on the previous one:

```scala
// context2 is dependent on value1:
context1.flatMap(value1 => context2)
```

The calls to `parseInt` and `Future.apply` above
are _independent_ of one another,
but `map` and `flatMap` can't exploit this.
We need a weaker construct---one
that doesn't guarantee sequencing---to
achieve the result we want.
In this chapter we will look at three type classes
that support this pattern:

  - `Semigroupal` encompasses
    the notion of composing pairs of contexts.
    Cats provides a [`cats.syntax.apply`][cats.syntax.apply] module
    that makes use of `Semigroupal` and `Functor`
    to allow users to sequence functions with multiple arguments.
    
  - `Parallel` converts
    types with a `Monad` instance
    to a related type with a `Semigroupal` instance.

  - `Applicative` extends `Semigroupal` and `Functor`.
    It provides a way of applying functions to parameters within a context.
    `Applicative` is the source of the `pure` method
    we introduced in @sec:monads.

Applicatives are often formulated in terms of function application,
instead of the semigroupal formulation that is emphasised in Cats.
This alternative formulation provides a link
to other libraries and languages such as Scalaz and Haskell.
We'll take a look at different formulations of Applicative,
as well as the relationships between
`Semigroupal`, `Functor`, `Applicative`, and `Monad`,
towards the end of the chapter.
