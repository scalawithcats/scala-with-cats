## Applicatives, Disjunctions, Validations... Oh My!

The `\/` type is primarily a monad---its `ap` provides monadic semantics as we might expect:

~~~ scala
type StringOr[A] = String \/ A

val fail1: StringOr[Int] = "Fail1".left
val fail2: StringOr[Int] = "Fail2".left

Applicative[StringOr].apply2(fail1, fail2)(_ + _)
// res7: StringOr[Int] = -\/(Fail1)
~~~
