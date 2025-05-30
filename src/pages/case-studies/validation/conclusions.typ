#import "../../stdlib.typ": info, warning, solution
== Summary


This case study has been an exercise in
removing rather than building abstractions.
We started with a fairly complex `Check` type.
Once we realised we were conflating two concepts,
we separated out `Predicate`
leaving us with something that could be implemented with `Kleisli`.

<!--
`Predicate` is very much like a stripped down version
of the matchers found in testing libraries like ScalaTest and Specs2.
One next step would be to develop
a more elaborate predicate library along these lines.
There are a few other directions to consider.

With the current representation of `Predicate`
there is no way to implement logical negation.
To implement negation we need to know the error message
that a successful predicate would have returned if it had failed
(so that the negation can return that message).
One way to implement this is to have a predicate return a `Boolean` flag
indicating success or failure and the associated message.

We could also do better in how error messages are represented.
At the moment there is no indication with an error message
of the structure of the predicates that failed.
For example, if we represent error messsages as a `List[String]`
and we get back the message:

```scala mdoc:silent
List("Must be longer than 4 characters",
     "Must not contain a number")
```

does this message indicate a failing conjunction (two `ands`)
or a failing disjunction (two `ors`)?
We can probably guess in this case
but in general we don't have sufficient information to work this out.
We can solve this problem by wrapping all messages in a type as follows:

```scala mdoc:silent:reset-object
sealed trait Structure[E]

final case class Or[E](messages: List[Structure[E]])
  extends Structure[E]

final case class And[E](messages: List[Structure[E]])
  extends Structure[E]

final case class Not[E](messages: List[Structure[E]])
  extends Structure[E]

final case class Pure[E](message: E)
  extends Structure[E]
```

We can simplify this structure by converting all predicates into a normal form.
For example, if we use disjunctive normal form
the structure of the predicate will always be
a disjunction (logical or) of conjunctions (logical and).
By doing so we could errors as a `List[List[Either[E, E]]]`,
with the outer list representing disjunction,
the inner list representing conjunction,
and the `Either` representing negation.
-->

We made several design choices above
that reasonable developers may disagree with.
Should the method that converts a `Predicate` to a function
really be called `run` instead of, say, `toFunction`?
Should `Predicate` be a subtype of `Function` to begin with?
Many functional programmers prefer to avoid subtyping
because it plays poorly with implicit resolution and type inference,
but there could be an argument to use it here.
As always the best decisions depend on the context
in which the library will be used.
