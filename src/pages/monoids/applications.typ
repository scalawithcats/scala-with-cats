#import "../stdlib.typ": info, warning, solution
== Applications of Monoids


We now know what a monoid is---an abstraction of the concept of adding or combining---but where is it useful?
Here are a few big ideas where monoids play a major role.
These are explored in more detail in case studies later in the book.

=== Big Data


In big data applications like Spark and Flink we distribute data analysis over many machines,
giving fault tolerance and scalability.
This means each machine will return results over a portion of the data,
and we must then combine these results to get our final result.
In the vast majority of cases this can be viewed as a monoid.

If we want to calculate how many total visitors a web site has received,
that means calculating an `Int` on each portion of the data.
We know the monoid instance of `Int` is addition, which is the right way to combine partial results.

If we want to find out how many unique visitors a website has received,
that's equivalent to building a `Set[User]` on each portion of the data.
We know the monoid instance for `Set` is the set union, which is the right way to combine partial results.

If we want to calculate 99% and 95% response times from our server logs,
we can use a data structure called a `QTree` for which there is a monoid.

Hopefully you get the idea. Almost every analysis that we might want to do over a large data set is a monoid,
and therefore we can build an expressive and powerful analytics system around this idea.
This is exactly what Twitter's Algebird and Summingbird projects have done.
We explore this idea further in the map-reduce case study in @sec:map-reduce.

=== Distributed Systems


In a distributed system,
different machines may end up with different views of data.
For example,
one machine may receive an update that other machines did not receive.
We would like to reconcile these different views,
so every machine has the same data if no more updates arrive.
This is called *eventual consistency*.

A particular class of data types support this reconciliation.
These data types are called conflict-free replicated data types (CRDTs).
The key operation is the ability to merge two data instances,
with a result that captures all the information in both instances.
This operation relies on having a monoid instance.
We explore this idea further in the CRDT case study.


=== Monoids in the Small


The two examples above are cases where monoids inform the entire system architecture.
There are also many cases where having a monoid around makes it easier to write a small code fragment.
We'll see lots of examples in the remainder of this book.
