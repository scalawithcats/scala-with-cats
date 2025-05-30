#import "../../stdlib.typ": info, warning, solution
== Summary


In this case study we've seen how we can use type classes
to model a simple CRDT, the GCounter, in Scala.
Our implementation gives us a lot of flexibility and code reuse:
we aren't tied to the data type we "count",
nor to the data type that maps machine IDs to counters.

The focus in this case study has been
on using the tools that Scala provides,
not on exploring CRDTs.
There are many other CRDTs,
some of which operate in a similar manner to the GCounter,
and some of which have very different implementations.
A [fairly recent survey][link-crdt-survey]
gives a good overview of many of the basic CRDTs.
However this is an active area of research
and we encourage you to read the recent publications in the field
if CRDTs and eventually consistency interest you.
