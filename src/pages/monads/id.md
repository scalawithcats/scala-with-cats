## The Identity Monad

We can unify monadic and normal code by using the `Id` monad. The `Id` monad provides a monad instance (and many other instances) for plain values. Note that such values are not wrapped in any class. They continue to be the plain values we started with. To access it's instances we require `scalaz.Id._`.

~~~ scala
import scalaz.Id._
import scalaz.syntax.monad._

3.point[Id]
// res2: scalaz.Id.Id[Int] = 3

3.point[Id] flatMap (_ + 2)
// res3: scalaz.Id.Id[Int] = 5

3.point[Id] + 2
// res4: Int = 5
~~~
