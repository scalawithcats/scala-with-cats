### *Traverse* in Cats

Our `listTraverse` and `listSequence` methods work with any type of `Applicative` effect,
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

Cats provides instances for `List`, `Vector`, `Stream`, `Option`, `Xor`, and a variety of other types.
We can summon instances as usual using `Traverse.apply` as usual:

```tut:book
import cats.Traverse,
       cats.instances.list._

Traverse[List]
```

The `traverse` and `sequence` methods work exactly as described in the previous section:

```tut:book:invisible
import scala.concurrent._,
       scala.concurrent.duration._,
       scala.concurrent.ExecutionContext.Implicits.global,
       cats.instances.future._

val hostnames = List("alpha.example.com", "beta.example.com", "gamma.demo.com")

def getUptime(hostname: String): Future[Int] =
  Future(hostname.length * 60) // just for demonstration
```

```tut:book
import scala.concurrent._,
       scala.concurrent.duration._,
       scala.concurrent.ExecutionContext.Implicits.global,
       cats.instances.future._

Await.result(Traverse[List].traverse(hostnames)(getUptime), Duration.Inf)

val numbers = List(Future(1), Future(2), Future(3))

Await.result(Traverse[List].sequence(numbers), Duration.Inf)
```

There are also syntax versions of the methods, imported via [`cats.syntax.traverse`]:

```tut:book
import cats.syntax.traverse._

Await.result(hostnames.traverse(getUptime), Duration.Inf)

Await.result(numbers.sequence, Duration.Inf)
```

As you can see, this is much more compact and readable
than the `foldLeft` we started with earlier this chapter!
