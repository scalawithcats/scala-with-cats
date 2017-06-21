## The GCounter

Let's look at one particular CRDT implementation.
Then we'll attempt to generalise properties
to see if we can find a general pattern.

The data structure we will look at is called a *GCounter*.
It is a distributed *increment-only* counter.
It can be used, for example,
for counting the number of visitors to a site
where requests are served by many web servers.

### Simple Counters

To see why a straightforward counter won't work,
imagine we have two servers storing a count of visitors.
Let's call the machines `A` and `B`.
Each machine is storing just an integer counter
and the counters all start at zero.

```
A: 0
B: 0
```

`A` serves three visitors, and `B` two.

```
A: 3
B: 2
```

Now the machines want to merge their counters
so they each have an up-to-date view of the total number of visitors.
At this point we know the machines should add together their counters,
because we know the history of their interactions.
However, there is nothing in the data the machines store that records this.
Nonetheless, let's use addition as our strategy for merging counters and see what happens.

```
A: 5
B: 5
```

Now `A` serves a single visitor.

```
A: 6
B: 5
```

The machines attempt to merge counters again.
If they use addition as the merging algorithm they will end up with

```
A: 11
B: 11
```

This is clearly wrong!
There have only been six visitors in total.
Do we need to store the complete history of interactions
to be able to compute the correct value?
It turns out we do not, so let's look at the GCounter now
to see how it solves this problem in an elegant way.

### GCounters

The first clever idea in the GCounter is
to have each machine storing a *separate* counter
for every machine (including itself) that it knows about.
In the previous example we had two machines, `A` and `B`.
In this situation both machines would store a counter for `A`
and a counter for `B`.

```
Machine A   Machine B
A: 0        A: 0
B: 0        B: 0
```

The rule with these counters is that
a given machine is only allowed to increment it's own counter.
If `A` serves 3 visitors and `B` serves two visitors the counters will look like

```
Machine A   Machine B
A: 3        A: 0
B: 0        B: 2
```

Now when two machines merge their counters
the rule is to take the largest value stored for a given machine.
Given the state above, when `A` and `B` merge counters the result will be

```
Machine A   Machine B
A: 3        A: 3
B: 2        B: 2
```

as `3` is the largest value stored for the `A` counter,
and `2` is the largest value stored for the `B` counter.
The combination of only allowing machines to increment their counter
and choosing the maximum value on merging
means we get the correct answer
without storing the complete history of interactions.

If a machine wants to calculate the current value of the counter
(given its current knowledge of other machines' state)
it simply sums up all the per-machine counter.
Given the state

```
Machine A   Machine B
A: 3        A: 3
B: 2        B: 2
```

each machine would report the current values as `3 + 2 = 5`.

### Exercise: GCounter Implementation

We can implement a GCounter with the interface

```tut:book:silent
final case class GCounter(counters: Map[String, Int]) {
  def increment(machine: String, amount: Int) =
    ???

  def get: Int =
    ???

  def merge(that: GCounter): GCounter =
    ???
}
```

where we represent machine IDs as `Strings`.

Finish the implementation.

<div class="solution">
Hopefully the description above was clear enough that
you can get to an implementation like the below.

```tut:book:silent
final case class GCounter(counters: Map[String, Int]) {
  def increment(machine: String, amount: Int) =
    GCounter(counters + (machine -> (amount + counters.getOrElse(machine, 0))))

  def get: Int =
    counters.values.sum

  def merge(that: GCounter): GCounter =
    GCounter(that.counters ++ {
      for((k, v) <- counters) yield {
        k -> (v max that.counters.getOrElse(k,0))
      }
    })
}
```
</div>
