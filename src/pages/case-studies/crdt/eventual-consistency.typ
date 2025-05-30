#import "../../stdlib.typ": info, warning, solution
== Eventual Consistency


As soon as a system scales beyond a single machine
we have to make a fundamental choice about how we manage data.

One approach is to build a system that is _consistent_,
meaning that all machines have the same view of data.
For example, if a user changes their password
then all machines that store a copy of that password
must accept the change
before we consider the operation to have completed successfully.

Consistent systems are easy to work with
but they have their disadvantages.
They tend to have high latency
because a single change can result in
many messages being sent between machines.
They also tend to have relatively low uptime
because outages can cut communications
between machines creating a _network partition_.
When there is a network partition,
a consistent system may refuse further updates
to prevent inconsistencies across machines.

An alternative approach is an _eventually consistent_ system.
This means that at any particular point in time
machines are allowed to have differing views of data.
However, if all machines can communicate
and there are no further updates
they will eventually all have the same view of data.

Eventually consistent systems require
less communication between machines
so latency can be lower.
A partitioned machine can still accept updates
and reconcile its changes when the network is fixed,
so systems can also have better uptime.

The big question is:
how do we do this reconciliation between machines?
CRDTs provide one approach to the problem.
