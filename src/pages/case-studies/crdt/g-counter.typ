#import "../../stdlib.typ": info, warning, solution
== The GCounter


Let's look at one particular CRDT implementation.
Then we'll attempt to generalise properties
to see if we can find a general pattern.

The data structure we will look at is called a _GCounter_.
It is a distributed _increment-only_ counter
that can be used, for example,
to count the number of visitors to a web site
where requests are served by many web servers.

=== Simple Counters


To see why a straightforward counter won't work,
imagine we have two servers storing a simple count of visitors.
Let's call the machines `A` and `B`.
Each machine is storing an integer counter
and the counters all start at zero
as shown in @fig:crdt:simple-counter1.

#figure(image("simple-counter1.svg"), caption: [Simple counters: initial state])
<fig:crdt:simple-counter1>

Now imagine we receive some web traffic.
Our load balancer distributes five incoming requests
to `A` and `B`, `A` serving three visitors and `B` two.
The machines have inconsistent views of the system state
that they need to _reconcile_ to achieve consistency.
One reconciliation strategy with simple counters
is to exchange counts and add them
as shown in @fig:crdt:simple-counter3.

#figure(image("simple-counter3.svg"), caption: [Simple counters: first round of requests and reconciliation])
<fig:crdt:simple-counter3>

So far so good, but things will start to fall apart shortly.
Suppose `A` serves a single visitor,
which means we've seen six visitors in total.
The machines attempt to reconcile state again using addition
leading to the answer shown in @fig:crdt:simple-counter5.

#figure(image("simple-counter5.svg"), caption: [Simple counters: second round of requests and (incorrect) reconciliation])
<fig:crdt:simple-counter5>

This is clearly wrong!
The problem is that simple counters
don't give us enough information about
the history of interactions between the machines.
Fortunately we don't need to store the _complete_ history
to get the correct answer---just a summary of it.
Let's look at how the GCounter solves this problem.

=== GCounters


The first clever idea in the GCounter is
to have each machine storing a _separate_ counter
for every machine it knows about (including itself).
In the previous example we had two machines, `A` and `B`.
In this situation both machines
would store a counter for `A` and a counter for `B`
as shown in @fig:crdt:g-counter1.

#figure(image("g-counter1.svg"), caption: [GCounter: initial state])
<fig:crdt:g-counter1>

The rule with GCounters is that
a given machine is only allowed to increment its own counter.
If `A` serves three visitors and `B` serves two visitors
the counters look as shown in @fig:crdt:g-counter2.

#figure(image("g-counter2.svg"), caption: [GCounter: first round of web requests])
<fig:crdt:g-counter2>

When two machines reconcile their counters
the rule is to take the largest value stored for each machine.
In our example, the result of the first merge
will be as shown in @fig:crdt:g-counter3.

#figure(image("g-counter3.svg"), caption: [GCounter: first reconciliation])
<fig:crdt:g-counter3>

Subsequent incoming web requests are handled using the
increment-own-counter rule and
subsequent merges are handled using the
take-maximum-value rule,
producing the same correct values for each machine
as shown in @fig:crdt:g-counter5.

#figure(image("g-counter5.svg"), caption: [GCounter: second reconciliation])
<fig:crdt:g-counter5>

GCounters allow each machine to keep
an accurate account of the state of the whole system
without storing the complete history of interactions.
If a machine wants to calculate
the total traffic for the whole web site,
it sums up all the per-machine counters.
The result is accurate or near-accurate
depending on how recently we performed a reconciliation.
Eventually, regardless of network outages,
the system will always converge on a consistent state.

=== Exercise: GCounter Implementation


We can implement a GCounter with the following interface,
where we represent machine IDs as `Strings`.

```scala mdoc:reset-object:silent
final case class GCounter(counters: Map[String, Int]) {
  def increment(machine: String, amount: Int) =
    ???

  def merge(that: GCounter): GCounter =
    ???

  def total: Int =
    ???
}
```

Finish the implementation!

#solution[
Hopefully the description above was clear enough that
you can get to an implementation like the one below.

```scala mdoc:silent:reset-object
final case class GCounter(counters: Map[String, Int]) {
  def increment(machine: String, amount: Int) = {
    val value = amount + counters.getOrElse(machine, 0)
    GCounter(counters + (machine -> value))
  }

  def merge(that: GCounter): GCounter =
    GCounter(that.counters ++ this.counters.map {
      case (k, v) =>
        k -> (v max that.counters.getOrElse(k, 0))
    })

  def total: Int =
    counters.values.sum
}
```
]
