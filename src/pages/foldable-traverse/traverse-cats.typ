#import "../stdlib.typ": info, warning, solution, href
=== Traverse in Cats


Our `listTraverse` and `listSequence` methods
work with any type of `Applicative`,
but they only work with one type of sequence: `List`.
We can generalise over different sequence types using a type class,
which brings us to Cats' `Traverse`.
Here's the abbreviated definition:

```scala
package cats

trait Traverse[F[_]] {
  def traverse[G[_]: Applicative, A, B]
      (inputs: F[A])(func: A => G[B]): G[F[B]]

  def sequence[G[_]: Applicative, B]
      (inputs: F[G[B]]): G[F[B]] =
    traverse(inputs)(identity)
}
```

Cats provides instances of `Traverse`
for `List`, `Vector`, `Stream`, `Option`, `Either`,
and a variety of other types.
We can summon instances as usual using `Traverse.apply`
and use the `traverse` and `sequence` methods
as described in the previous section.

```scala mdoc:invisible
import scala.concurrent.*
import scala.concurrent.duration.*
import scala.concurrent.ExecutionContext.Implicits.global

val hostnames = List(
  "alpha.example.com",
  "beta.example.com",
  "gamma.demo.com"
)

def getUptime(hostname: String): Future[Int] =
  Future(hostname.length * 60)
```

```scala mdoc:silent
import cats.Traverse

val totalUptime: Future[List[Int]] =
  Traverse[List].traverse(hostnames)(getUptime)
```

We get the same result as before.

```scala mdoc
Await.result(totalUptime, 1.second)
```

There are also syntax versions of the methods.

```scala mdoc:silent
import cats.syntax.all.*

val numbers  = hostnames.traverse(getUptime)
val numbers2 =
  List(Future(1), Future(2), Future(3)).sequence
```

As you can see, this is much more compact and readable
than the `foldLeft` code we started with earlier this chapter!
