### *Traverse* in Cats

Our `listTraverse` and `listSequence` methods
work with any type of `Applicative` effect,
but they only work with one type of sequence: `List`.
We can generalise over different sequence types using a type class,
which brings us to Cats' `Traverse`.
Here's the abbreviated definition:

```scala
package cats

trait Traverse[F[_]] {
  def traverse[G[_] : Applicative, A, B](inputs: F[A])(func: A => G[B]): G[F[B]]

  def sequence[G[_] : Applicative, B](inputs: F[G[B]]): G[F[B]] =
    traverse(inputs)(func)
}
```

Cats provides instances OF `Traverse`
for `List`, `Vector`, `Stream`, `Option`, `Xor`,
and a variety of other types.
We can summon instances as usual using `Traverse.apply` as usual
and use the `traverse` and `sequence` methods
as described in the previous section:

```tut:book:invisible
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

val hostnames = List("alpha.example.com", "beta.example.com", "gamma.demo.com")

def getUptime(hostname: String): Future[Int] =
  Future(hostname.length * 60)
```

```tut:book:silent
import cats.Traverse
import cats.instances.future._
import cats.instances.list._
```

```tut:book
Await.result(Traverse[List].traverse(hostnames)(getUptime), Duration.Inf)
```

```tut:book:silent
val numbers = List(Future(1), Future(2), Future(3))
```

```tut:book
Await.result(Traverse[List].sequence(numbers), Duration.Inf)
```

There are also syntax versions of the methods,
imported via [`cats.syntax.traverse`][cats.syntax.traverse]:

```tut:book:silent
import cats.syntax.traverse._
```

```tut:book
Await.result(hostnames.traverse(getUptime), Duration.Inf)
Await.result(numbers.sequence, Duration.Inf)
```

As you can see, this is much more compact and readable
than the `foldLeft` code we started with earlier this chapter!
