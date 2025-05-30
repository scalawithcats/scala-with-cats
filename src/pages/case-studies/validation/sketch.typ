#import "../../stdlib.typ": info, warning, solution
== Sketching the Library Structure


Let's start at the bottom,
checking individual pieces of data.
Before we start coding
let's try to develop a feel
for what we'll be building.
We can use a graphical notation to help us.
We'll go through our goals one by one.

*Providing error messages*

Our first goal requires us to
associate useful error messages with a check failure.
The output of a check could be either the value being checked,
if it passed the check, or some kind of error message.
We can abstractly represent this as a value in a context,
where the context is the possibility of an error message
as shown in @fig:validation:result.

#figure(image("result.svg"), caption: [A validation result])
<fig:validation:result>

A check itself is therefore a function that
transforms a value into a value in a context
as shown in @fig:validation:check.

#figure(image("check.svg"), caption: [A validation check])
<fig:validation:check>

*Combine checks*

How do we combine smaller checks into larger ones?
Is this an applicative or semigroupal
as shown in @fig:validation:applicative?

#figure(image("applicative.svg"), caption: [Applicative combination of checks])
<fig:validation:applicative>

Not really.
With applicative combination,
both checks are applied to the same value
and result in a tuple with the value repeated.
What we want feels more like a monoid
as shown in @fig:validation:monoid.
We can define a sensible identity---a check that always passes---and
two binary combination operators---_and_ and _or_:

#figure(image("monoid.svg"), caption: [Monoid combination of checks])
<fig:validation:monoid>

We'll probably be using _and_ and _or_ about equally often
with our validation library
and it will be annoying to continuously
switch between two monoids for combining rules.
We consequently won't actually use the monoid API:
we'll use two separate methods, `and` and `or`, instead.

*Accumulating errors as we check*

Monoids also feel like a good mechanism
for accumulating error messages.
If we store messages as a `List` or `NonEmptyList`,
we can even use a pre-existing monoid from inside Cats.

*Transforming data as we check it*

In addition to checking data,
we also have the goal of transforming it.
This seems like it should be a `map` or a `flatMap`
depending on whether the transform can fail or not,
so it seems we also want checks to be a monad
as shown in @fig:validation:monad.

#figure(image("monad.svg"), caption: [Monadic combination of checks])
<fig:validation:monad>

We've now broken down our library into familiar abstractions
and are in a good position to begin development.
