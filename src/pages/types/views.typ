#import "../stdlib.typ": exercise, solution
== Sets and Constraints <sec:types:views>

What is a type?
Here we'll address this question from the programmer's perspective,
but I want to note that there is a subfield within mathematics and philosophy known as type theory.
There are some references in the conclusions if you want to follow that direction.

The most common view is that types define a set of values.
For example, an `Int` in Scala is 32-bits,
and as such defines a set of 4,294,967,296 possible values.
When we define a type by enumerating all the possible values of that type,
we are working with an extensional definition.
This is a natural approach to take,
not least because we need to tell the programming language how to represent values in memory,
and the extensional view provides this.

The extensional view, however, doesn't provide any *encapsulation* or *information hiding*.
Knowing the representation can be a problem when that integer represents, say,
an index into an array, or an age, or a timestamp.
In these cases we have access to a whole range of operations
that aren't meaningful on the data.
For example, neither indices nor ages can be negated,
but nonetheless we can negate any index or age that is represented as an `Int`.
Similarly, we can perform bitwise operations on machine integers,
but this is not semantically meaningful for, say, a timestamp.
Furthermore, as we'll see in @sec:indexed-types,
it can be useful to have types that have no representation,
which the extensional view doesn't have much to say about.

This brings us to an alternate view of types,
the intensional view.
Instead of thinking of a type in terms of its representation,
we can think of a type in terms of the conditions, invariants, or constraints that hold for elements of that type.
This may in turn imply a set of operations that are valid on our types.
So, for example,
we can think of age (in years) as a non-negative integer with an increment operation,
but no decrement operation (we, unfortunately, cannot get younger.)
Similarly,
indices are non-negative integers within the range of the array they refer to,
names are non-empty strings,
and email addresses are case insensitive strings with a username and domain separated by an `@`.

We might argue that our `Int` example above
_is_ defined by a constraint: namely it's an integer that fits into 32-bits.
This is true!
This constraint also implies which operations are available on `Int`.
We cannot, for example, try to convert an `Int` to upper case;
this is meaningless.
Remember that we're taking two different views on the same concept.
It's expected that we can translate between these views in many cases.
The problem is the purely extensional view couples operations and representation.
We cannot represent, say, a timestamp as an `Int`
and not make meaningless bitwise operations available
if we only have the extensional view.

Decoupling operations and representation sounds a lot like programming to an interface.
Indeed this is true, and we'll look at this in much more detail in @sec:codata.
In this chapter we'll look at opaque types, which directly decouple type and representation,
allowing us to reuse a representation as a different type.
However, before doing so I want to spend more time on the mindset shift that the intensional view promotes.
