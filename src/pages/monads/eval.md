## *Eval* #{eval}

[`cats.Eval`][cats.Eval] is a monad that allows us to abstract over different *models of evaluation*. We typically hear of two such models: *eager* and *lazy*. `Eval` throws in a further distinction of *memoized* and *unmemoized* to create three models of evaluation:

 - *now*---evaluated once immediately (equivalent to `val`);
 - *later*---evaluated once when value is needed (equivalent to `lazy val`);
 - *always*---evaluated every time value is needed (equivalent to `def`).

<div class="callout callout-danger">
TODO: Explain why this is useful. Maybe a model of lazy evaluation? Fibonacci numbers?
</div>

### Eager, lazy, memoized, oh my!

What do these terms mean?

*Eager* computations happen immediately, whereas *lazy* computations happen on access. For example, Scala `vals` are eager definitions, whereas `defs` and `lazy vals` are lazy:

```scala
// vals are eager.
// They are computed immediately on declaration:
val x = {
  println("Computing X")
  1 + 1
}
// Computing X
// x: Int = 2

x // access the val
// res2: Int = 2
```

```scala
// defs and lazy vals are lazy.
// They aren't computed until they are accessed:
def y = {
  println("Computing Y")
  1 + 1
}
// y: Int

y // access the def
// Computing Y
// res5: Int = 2
```

*Memoized* computations happen once. After that, their results are cached and re-used on subsequent accesses without being re-computed. Scala `vals` and `lazy vals` are memoized, whereas `defs` are not:

```scala
// vals and lazy vals are memoized.
// They are computed once and cached.
// Subsequent accesses do not re-compute the result:
val x = {
  println("Computing X")
  1 + 1
}
// Computing X
// x: Int = 2

x // access the val
// res9: Int = 2

x // access the val a second time
// res10: Int = 2
```

```scala
// defs are not memoized.
// They are re-computed every time they are accessed:
def y = {
  println("Computing Y")
  1 + 1
}
// y: Int

y // access the def
// Computing Y
// res13: Int = 2

y // access the def a second time
// Computing Y
// res14: Int = 2
```

The table below shows a summary of these behaviours:

+------------------+-------------------------+--------------------------+
|                  | Eager                   | Lazy                     |
+==================+=========================+==========================+
| Memoized         | `val`, `Eval.now`       | `lazy val`, `Eval.later` |
+------------------+-------------------------+--------------------------+
| Not memoized     | `def`, `Eval.always`    | -                        |
+------------------+-------------------------+--------------------------+

### Eval's models of evaluation


### Motivation for Eval

<div class="callout callout-danger">
TODO:

`Eval` is a type that Cats uses to abstract over evaluation strategies (lazy, eager, etc).
See more information here:

- https://github.com/typelevel/cats/blob/master/core/src/main/scala/cats/Eval.scala
- http://eed3si9n.com/herding-cats/Eval.html
- Erik's talk from Typelevel Philly (once the video is up)
</div>

### Evaluation Strategies

<div class="callout callout-danger">
TODO:

- now
- later
- always
</div>

### Trampolining

<div class="callout callout-danger">
TODO:

- Discuss trampolining
- Discuss foldRight on Foldable
- Examples of folding with different strategies
- Maybe show a stack explosion
</div>

### Exercises

<div class="callout callout-danger">
TODO:

- Exercises
</div>
