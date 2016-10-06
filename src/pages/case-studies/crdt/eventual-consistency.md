## Eventual Consistency

As soon as a system scales beyond a single machine
we have to make a fundamental choice about how we manage data.
We can build a system that is *consistent*,
meaning that all machines have the same view of data.
For example, if a user changes their password
then all machines that store a copy of that password
must accept the change
before we consider the operation to have completed successfully.

Consistent systems are simple to work with
but they have their disadvantages.
They tend to have high latency,
as every change can result is many messages being sent between machines.
They can also can have relatively low uptime.
A network problem can cause some machines to be unable to communicate with others.
This is called a network partition.
When there is a network partition
a consistent system may refuse further updates
as allowing them could result in data becoming inconsistent
between the partitioned systems.

An alternative approach is an *eventually consistent* system.
This means that if all machines can communicate
and there are no further updates
they will evenutally all have the same view of data.
However, at any particular point in time
machines are allowed to have differing views of data.

Latency can be lower because
eventually consistent systems require less communication between machines.
A partitioned machine can still accept updates
and reconcile its changes when the network is fixed,
so systems can also can have better uptime.
How exactly are we to do this reconciliation, though?
CRDTs are one approach to the problem.
