## *Apply* and *Applicative*

<div class="alert alert-error">
  TODO: This section needs editing or removing.
</div>

Cats provides two additional type classes that extend `Cartesian`:

- `Apply` extends `Cartesian` and `Functor`,
  adding an `ap` method to apply a parameter to a function
  within a context;

- `Applicative` extends `Apply`,
  adding a `pure` method that creates an "empty" value.

`Applicative` is, in turn, the basis of the `Monad` type class.
Here is a diagram showing the family:

![Monad type class hierarchy](src/pages/applicatives/hierarchy.png)

Neither `Apply` nor `Applicative` are particularly important
for the material in this book.
However, they form important building blocks in the hierarchy
of type classes we have discussed so far.
If you are interested in the theory side of things,
this section shows how everything hangs together.
If you are only concerned with the practical applications of Cats,
feel free to skip ahead to the next section.

### Applying Arguments to Functions With *Apply*

The `Apply` type class extends `Cartesian` and `Functor`
and introduces a new method, `ap`,
which applies a function to a parameter within a context.
In another language `ap` would be called `apply`,
but that name is already used for many other purposes in Scala:

```scala
trait Apply[F[_]] extends Functor[F] with Cartesian[F] {
  def ap[A, B](ff: F[A => B])(fa: F[A]): F[B]

  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)] =
    ap(map(fa)(a => (b: B) => (a, b)))(fb)
}
```

Note that `product` is defined in terms of `ap` and `map`.
There is an equivalence between these three methods that
allows any one of them to be defined in terms of the other two.

The intuitive reading of this definition is as follows:

- `map` over `F[A]` to produce a value of type `F[B => (A, B)]`;
- apply `F[B]` to `F[B => (A, B)]` to get a value of type `F[B]`.

By defining one of these methods in terms of the other two,
we ensure that the definitions are consistent
for all implementations of `Apply`.

### Introducing New Instances With *Applicative*

The `Applicative` type class extends `Apply` adding in a `pure` value:

```scala
trait Applicative[F[_]] extends Apply[F] {
  def pure[A](value: A): F[A]
}
```

This is the same `pure` we saw in `Monad`.
It constructs a new applicative instance from an unwrapped value.

### Why *Xor* Doesn't Accumulate Errors

As we can see from the type hierarchy, `Monad` extends `Applicative`.
The default implementation defines
all of the methods above in terms of `flatMap` and `pure`.
Users get a complete set of consistent semantics
based on just these two methods:

```scala
def map[A, B](fa: F[A])(f: A => B): F[B] =
  flatMap(fa)(a => pure(f(a)))

def ap[A, B](ff: F[A => B])(fa: F[A]): F[B] =
  flatMap(ff)(f => map(fa)(f))

def product[A, B](fa: F[A], fb: F[B]): F[(A, B)] =
  flatMap(fa)(a => map(fb)(b => (a, b)))
```

Note that the implementation of `product`
is essentially monadic comprehension.
This is what gives the `product` method for `Xor`
the fail-fast semantics we saw earlier.

Fortunately, Cats provides another data type called `Validated`
that is an `Applicative` but not a `Monad`.
This allows the authors to provide
an implementation of `product` that preserves errors.
We'll discuss this type in the next section.
