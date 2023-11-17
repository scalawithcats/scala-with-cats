### Reifying Continuations to a Stack

We've seen two uses of reification so far:

1. we reified constructor and combinators methods as data; and
2. we reified the abstract concept of continuations as functions in our program.

We'll now see a third use, reifying continuations-as-functions as data.
We can start by applying the same recipe as before: we create a case for each place in which we construct a continuation.
In our interpreter loop this is for `Append`, `OrElse`, and `Repeat`. We also construct a continuation using the identity function when we first call `loop`, which represents the continuation to call when the loop has finished. This means we need four cases.

```scala
enum Continuation {
  case AppendK
  case OrElseK
  case RepeatK
  case DoneK
}
```

What data does each case next to hold?
Let's let look at the structure of the cases within the CPS interpreter.
The case for `Append` is typical.

```scala
case Append(left, right) =>
  val k: Cont = _ match {
    case None    => cont(None)
    case Some(i) => loop(right, i, cont)
  }
  loop(left, idx, k)
```

The continuation `k` captures the `Regexp` `right` and the continuation `cont`.
Our reification should reflect this by holding the same data.
If we consider all the cases we end up with the following definition.

```scala
enum Continuation {
  case AppendK(right: Regexp, next: Continuation)
  case OrElseK(second: Regexp, index: Int, next: Continuation)
  case RepeatK(regexp: Regexp, index: Int, next: Continuation)
  case DoneK
}
```


Now we can rewrite the interpreter loop using these types.

```scala
def loop(
    regexp: Regexp,
    idx: Int,
    cont: Continuation
): Call =
  regexp match {
    case Append(left, right) =>
      val k: Continuation = AppendK(right, cont)
      Call.Loop(left, idx, k)

    case OrElse(first, second) =>
      val k: Continuation = OrElseK(second, idx, cont)
      Call.Loop(first, idx, k)

    case Repeat(source) =>
      val k: Continuation = RepeatK(regexp, idx, cont)
      Call.Loop(source, idx, k)

    case Apply(string) =>
      Call.Continue(
        Option.when(input.startsWith(string, idx))(idx + string.size),
        cont
      )

    case Empty =>
      Call.Continue(None, cont)
  }
```

At this point you're probably wondering what we have achieved with this code transformation. Our end goal, which is now in reach, is to create a stack-safe interpreter. We'll do this in just a moment, when we introduce trampolining. Before we do, let's spend a bit longer looking at the data structures we've created. Our reified continuations have a structure that is similar to a `List`. `DoneK` is equivalent to the empty list. The other cases all have some data, which we can think of as the head, and a tail element that is the next continuation. We construct continuations by adding elements to the front of the existing continuation, which is exactly how we construct lists. Finally, we use continuations from front-to-back; in other words in last-in-first-out (LIFO) order. This is the correct access pattern to use a list efficiently, and also the access pattern that defines a stack. Reifying the continuations has reified the stack, and this allows us to run the interpreter loop without using stack space.
