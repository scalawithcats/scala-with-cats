# *Traverse*

In the last chapter we saw how `Cartesian` allowed us to zip values within a context,
and how `Applicative` used this concept to apply arguments to functions within a context.
In this chapter we will see a new type class called [`cats.Traverse`],
which uses `Applicatives` to abstract over iteration patterns[^not-traverse].

[^not-traverse]: Don't confuse `Traverse`
with the `Traversable` type in the Scala standard library.
The former is a type class in Cats, while the latter is
the supertype of all sequences in the Scala collections framework.
You *can*, however, confuse [`cats.Traverse`]
with the equivalent type class in Scalaz, [`scalaz.Traversable`].

To motivate `Traverse` we will look at a common use case:
turning a `List[Future[A]]` into a `Future[List[A]]`.
As an example, suppose we have a function that fetches the traffic for a web server,
returning a snapshot value of type `Future[Int]`:

```tut:book
import scala.concurrent.Future
import scala.concurrent.{ExecutionContext => EC}
import scala.concurrent.ExecutionContext.Implicits.global

def getTraffic(hostname: String)(implicit ec: EC): Future[Int] =
  ???
```

Now suppose we want to write a function that
polls a list of web servers and fetches the traffic from each:

```tut:book
def getAllTraffic(hostnames: List[String])(implicit ec: EC): Future[List[Int]] =
  ???
```

How do we implement this function?
If we simply map the `getTraffic` function over `hostnames`,
we get back a value of type `List[Future[Int]]`,
instead of the `Future[List[Int]]` we need:

```tut:book:fail
def getAllTraffic(hostnames: List[String]): Future[List[Int]] =
  hostnames.map(getTraffic)
```

To convert one type to the other, we need to traverse the `List` we have,
"zipping" the `Futures` together and accumulating a `List[Int]`.
Fortunately, the Scala standard library provices the `Future.sequence` method
to do just this:

```tut:book
def getAllTraffic(hostnames: List[String]): Future[List[Int]] =
  Future.sequence(hostnames.map(getTraffic))
```

The `Future.sequence` method is specific to `Futures` and sequences.
Given a sequence type `S`, it converts an `S[Future[A]]` to a `Future[S[A]]`.
Cats' `Traverse` type class generalises this to arbitrary inner and outer types,
and gives us more control over how values are combined on traversal.

# The *Traverse* Type Class

- Main operations (traverse and sequence)
- Laws

# *Traverse* in Cats

- Summoning instances
- Main methods
- Syntax

# *Unapply*, *traverseU*, and *sequenceU*

- Show when traverse and sequence fail
- Show traverseU and sequenceU fixing the problem
- Show how Unapply works
- Mention Scala 2.12 and SI-2712

# Summary
