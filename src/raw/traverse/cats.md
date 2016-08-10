## *Traverse* in Cats

It's time to see how we can use [`cats.Traverse`].
An instance `Traverse[F]` helps us iterate over values of type `F[A]`.
We can summon instances using `Traverse.apply` as usual:

```tut:book
import cats.Traverse
import cats.instances.list._

Traverse[List]
```

`Traverse` provides two main methods, `traverse` and `sequence`.
Here's an abbreviated definition:

```scala
package cats

trait Traverse[F[_]] extends Functor[F] {
  def traverse[G[_]: Applicative, A, B](input: F[A])(func: A => G[B]): G[F[B]]

  def sequence[G[_]: Applicative, A](fga: F[G[A]]): G[F[A]] =
    traverse(fga)(ga => ga)
}
```

The `sequence` method takes an `input` of type `F[G[A]]`
and returns a value of type `G[F[A]]`.
The `Traverse` instance iterates over `F` and uses a supplied
`Applicative` to combine the values of type `G[A]`.
