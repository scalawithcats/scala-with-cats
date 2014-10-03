---
layout: page
title: Monoids
---

In this section we explore our first type class: **monoids**. Let's start by looking a few types and operations on those types, and see what common principles we can extract.

Addition of `Int`s is a binary operation that is *closed*, meaning given two `Int`s we always get another `Int` back. There is also the *identity* element `0` with the property that `a + 0 = + 0 + a = a` for any `Int` `a`.

~~~ scala
scala> 2 + 1
res0: Int = 3

scala> 2 + 0
res1: Int = 2
~~~

There are also other properties of addition. For instance, it doesn't matter in what order we add elements as we always get the same result. This is a property known as *associativity*.

~~~ scala
scala> (1 + 2) + 3
res0: Int = 6

scala> 1 + (2 + 3)
res1: Int = 6
~~~

We can do the same things with multiplication that we did with addition if we use `1` as the identity.

~~~ scala
scala> (1 * 2) * 3
res2: Int = 6

scala> 1 * (2 * 3)
res3: Int = 6

scala> 2 * 3
res4: Int = 6
~~~

We can do the same things with `String`, using string concatenation as our binary operator and the empty string as the identity.

~~~ scala
scala> "" ++ "Hello"
res6: String = Hello

scala> "Hello" ++ ""
res7: String = Hello

scala> ("One" ++ "Two") ++ "Three"
res8: String = OneTwoThree

scala> "One" ++ ("Two" ++ "Three")
res9: String = OneTwoThree
~~~

Note I used `++` for string concatentation, instead of the more usual `+`, to suggest a parallel with sequence concatenation. And we can do exactly the same with sequence concatenation and the empty sequence as our identity.

We've seen a number of types which we can "add" and have an identity element. It will be no surprise to learn that this is a monoid. A simplified definition of it in Scalaz is:

~~~ scala
trait Monoid[A] {
  def append(f1: A, f2: => A): A
  def zero: A
}
~~~

where `append` is the binary operation and `zero` is the identity.

## Monoid Definition

Formally, a monoid for a type `A` is ...
