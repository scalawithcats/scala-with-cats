## Summary

We hit a big milestone in this chapter---we covered
our first type classes with fancy functional programming names:

 -  a `Semigroup` represents an addition or combination operation;
 -  a `Monoid` extends a `Semigroup` by adding an identity or "zero" element.

We can use `Semigroups` and `Monoids` by importing three things:
the type classes themselves, the instances for the types we care about,
and the semigroup syntax to give us the `|+|` operator:

```tut:book:silent
import cats.Monoid
import cats.instances.string._ // for Monoid
import cats.syntax.semigroup._ // for |+|
```

```tut:book
"Scala" |+| " with " |+| "Cats"
```

With the correct instances in scope,
we can set about adding anything we want:

```tut:book:silent
import cats.instances.int._    // for Monoid
import cats.instances.option._ // for Monoid
```

```tut:book
Option(1) |+| Option(2)
```

```tut:book:silent
import cats.instances.map._ // for Monoid

val map1 = Map("a" -> 1, "b" -> 2)
val map2 = Map("b" -> 3, "d" -> 4)
```

```tut:book
map1 |+| map2
```

```tut:book:silent
import cats.instances.tuple._  // for Monoid


val tuple1 = ("hello", 123)
val tuple2 = ("world", 321)
```

```tut:book
tuple1 |+| tuple2
```

We can also write generic code that works with any type
for which we have an instance of `Monoid`:

```tut:book:silent
def addAll[A](values: List[A])
      (implicit monoid: Monoid[A]): A =
  values.foldRight(monoid.empty)(_ |+| _)
```

```tut:book
add(List(1, 2, 3)
add(List(None, Some(1), Some(2)))
```

`Monoids` are a great gateway to Cats.
They're easy to understand and simple to use.
However, they're just the tip of the iceberg
in terms of the abstractions Cats enables us to make.
In the next chapter we'll look at *functors*,
the type class personification of the beloved `map` method.
That's where the fun really begins!
