#import "../stdlib.typ": exercise, solution, href
== Building Constraints <sec:types:constraints>

Most applications work by progressively adding structure to inputs.
We might receive data from, say, the network or a database.
We perform some checks on that data and remove instances that are invalid.
We then do some more work, which entails further checks, and so on.

For example, imagine we're implementing a sign up flow.
We start by asking for a user name and email address.
Basic checks could be requiring names that are not empty, and email addresses that contain an `@`.
We won't even let the user submit the form if these checks fail.
Once the form is submitted we'll move on to further checks.
For example, we might validate email addresses by sending them a verification email.

How should we represent these multiple levels of validation?
For example, how do we distinguish a string representing a name from one that is an email address?
How about an unverified email from a verified one?
The most common approach that I've seen, across many code bases, is to use ad hoc naming conventions.
For example, we might use the name `email` and `verifiedEmail` to distinguish the different kinds of email addresses
in method parameters and data structure,
while still representing both as strings.
#footnote[
    #href("https://en.wikipedia.org/wiki/Hungarian_notation")[Hungarian notation] is a more formal approach to
    this idea of encoding type information in names.
    Hungarian notation was popular within Microsoft and its ecosystem,
    but to the best of my knowledge it is no longer in common use.
]

Types provide a compelling alternative to naming schemes.
They enforce consistency of nomenclature,
while also representing this information in a form the compiler can check.
For example, if we have `EmailAddress` and `VerifiedEmailAddress` types,
not only do we have standard names,
but the compiler will tell us if we try to use an `EmailAddress` where a `VerifiedEmailAddress` is required,
or a `String` where an `EmailAddress` is required.
Furthermore, when we see an `EmailAddress` we know it's already been through some validation,
so we don't needlessly repeat validation, or worse, forget to do it.
This brings us to two principles:

1. Types should represent what we know about values, or in other words the invariants or constraints on values. A `String` could be any sequence of characters. A `VerifiedEmailAddress` is also a sequence of characters, but it's one that represents an email address that we have verified is active.

2. Whenever we establish an additional invariant or constraint we should change the type to reflect this additional information. So for example, an email address might start out as a `String`, become an `EmailAddress` if we have verified it looks like an email, and then become a `VerifiedEmailAddress` when we've successfully sent it a verification email and received a response.

A corollary of this approach is that we push constraints upstream.
Let me explain.
In a code base where validation is done on an ad-hoc basis,
we often end up with methods that can fail.
For example, a method to get the domain from an email,
where the email is represented as a `String`,
might have the signature

```scala
def domain(email: String): Option[String]
```

indicating that the `String` might not be a valid email.
In this case we push the error handling,
reflecting the constraint that we only work with valid email addresses,
onto the downstream code that deals with the result of calling this method.

When we work with types as constraints the signature becomes

```scala
def domain(email: EmailAddress): String
```

There is now no possibility of error, as an email address must contain a domain.
However, we have pushed the constraint, obtaining an `EmailAddress`,
onto the upstream code that calls this method.
At some point we must have conversions that could fail,
which requires error handling,
but this approach pushes error handling to the edges of the program.
This tends to result in a better user experience,
as the user is immediately notified of problems,
and also makes the code simpler to work with as overall less error handling is required.

Although this strategy is easiest to explain in the context of validation,
it's not restricted to this use case.
As an example, imagine writing an API for updates to a database table.
Some columns allow nulls and some do not.
When updating a nullable column our API could accept an `Option`,
with the `None` case meaning the column is set to null.
When updating a non-nullable column we could also accept an `Option`,
with the `None` case meaning we retain the column's existing value.
These two different meaning of the same type are a sure way to introduce errors,
with users nulling out columns they intended to leave unchanged.
The solution is the same: use different types for the different kinds of columns.
Here the constraints are not on the values represented by the type,
but on the behaviour associated with them.
