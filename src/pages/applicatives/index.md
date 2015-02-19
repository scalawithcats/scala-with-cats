# Applicatives

Applicative is a weaker abstraction than a monad. All monads are applicative but some applicatives are not monads.

Monads is context sensitive. Applicative is context free.

~~~ scala
def ap(fa: F[A])(fab: F[A => B]): F[B]
def pure(a: A): F[A]
~~~

Currying, abstracting over arity.

Try it: convert elements in an option into an option of a case class.

## Applicative Builder

`|@|`
