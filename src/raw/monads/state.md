## The *State* Monad

[`cats.data.State`][cats.data.State] allows us to pass some additional state around as part of a computation. We can read and modify the state as we run the computation, allowing us to model "mutable" state without using mutation.

### Creating and Unpacking State

Boiled down to its simplest form, an instance of `State[S, A]` represents a function of type `S => (S, A)`,
where `S` is the type of the state and `A` is the type of the result of the computation.

```tut:book
import cats.data.State

val a = State[Int, String] { state =>
  (state, s"The state is $state")
}
```

We can "run" our monad by supplying an initial state,
at which point we get out our final state and our result:

```tut:book
a.run(10)
```

Confused as to how this is useful? All will become clear.

<div class="callout callout-danger">
  TODO: Talk about `Eval`
</div>

### Composing and Transforming State

The power of the `State` monad comes from combining instances
that represent primitive operations on the state and previous results.

We can use several derived constructors to create variations on the `State` monad,
reading and writing the state to manipulate the result.
The three simplest constructors are as follows:

 - `get` extracts the state as the result;
 - `set` updates the state and returns unit as the result;
 - `pure` ignores the state and returns a supplied result.

```tut:book
State.get[Int].run(20)
State.set[Int](30).run(20)
State.pure[Int, String]("Result").run(20)
```

These building blocks don't do much on their own.
However, we can assemble them to into useful computations using `map` and `flatMap`:

```tut:book
val program: State[Int, (Int, Int, Int)] = for {
  a <- State.get[Int]
  _ <- State.set[Int](a + 1)
  b <- State.get[Int]
  _ <- State.set[Int](b + 1)
  c <- State.get[Int]
} yield (a, b * 10, c * 100)

program.run(1)
```

<div class="callout callout-danger">
  TODO: Examples of inspect and modify
</div>

### Exercise: Stacking State

<div class="callout callout-danger">
  TODO: Example of using state as a stack
</div>
