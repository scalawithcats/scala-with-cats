
## Abstracting Over Arity

Applicatives are most widely used as a means of abstracting over arity. We'll start with some simple Scala code that operates on two values, refactor it to produce a general combinator, and then further generalise the combinators across functions of different arities.

### Combining Errors

Suppose we want to read pairs of numbers from a file and operate on them using a binary function. We want to read exactly two numbers to avoid getting out of sync with our input, and we want to report all errors we encounter during reading:

~~~ scala
// Accumulate errors in a list:
type Result[A] = List[String] \/ A

// Read an Int from our "file":
def readInt(str: String): Result[Int] = {
  println("Reading " + str)
  str.parseInt.disjunction.leftMap(exn => List(s"Error reading $str"))
}

// Combine two Ints together:
def sum2(a: Int, b: Int): Int =
  a + b
~~~

If we try reading the pair using monads, we hit a problem. Monads fail fast---if we hit an error reading the first number, we don't read the second number. This violates both of the goals we stated above---our file can end up out of sync, and we never accumulate errors if both numbers are invalid:

~~~ scala
for {
  a <- readInt("foo")
  b <- readInt("bar")
} yield sum2(a, b)
// Reading foo
// res0: scalaz.\/[List[String],Int] = ↩
//   -\/(List(Error reading foo))
~~~

Let's define a new combinator called `merge2` to give us the behaviour we want. We'll take two `Results` as input and a `func` to combine them:

~~~ scala
def merge2[A, B, C](a: Result[A], b: Result[B], func: (A, B) => C): Result[C] =
  (a, b) match {
    case (\/-(a), \/-(b)) => func(a, b).right
    case (\/-(a), -\/(f)) => f.left
    case (-\/(e), \/-(b)) => e.left
    case (-\/(e), -\/(f)) => (e ++ f).left
  }

merge2(readInt("foo"), readInt("bar"), sum2)
// Reading foo
// Reading bar
// res1: Result[Int] = ↩
//   -\/(List(Error reading foo, Error reading bar))
~~~

Now we're in business. Our file never gets out of sync because we read both arguments before calling `merge2`. Furthermore out implementation `merge2` preserves all the errors we encounter (although we could easily change this behaviour if we wanted).

This is a good starting point but `merge2` only works with functions of two arguments. We can use nested calls to generalise to larger arities but it turns out this is quite unwieldy. To clean things up we need to introduce a new concept---*curried functions*.

### Curried Functions

A curried function accepts its arguments one at a time. The result of providing the first argument is a function that accepts the next argument, and so on until the function call is complete:

~~~ scala
val curriedSum2 = (a: Int) => (b: Int) => a + b
// curriedSum2: Int => (Int => Int) = <function1>

val temp = curriedSum2(1)
// temp: Int => Int = <function1>

temp(2)
// res2: Int = 3
~~~

We can encode any function that accepts arguments as a curried function. The Scala standard library provides the `curried` method to help us with this:

~~~ scala
val sum3 = (a: Int, b: Int, c: Int) => a + b + c
// sum3: (Int, Int, Int) => Int = <function3>

val curried3 = sum3.curried
// curried3: Int => (Int => (Int => Int)) = <function1>

curried3(1)(2)(3)
// res3: Int = 6
~~~

## Enter Applicatives

It will be easier to generalise `merge2` across arities if we reswrite it to work with curried functions. The resulting method, which we will call `merge`, is effectively `ap` specialised to our `Result` type:

~~~ scala
def merge[A, B](a: Result[A])(b: Result[A => B]): Result[B] =
  (a, b) match {
    case (\/-(a), \/-(b)) => b(a).right
    case (\/-(a), -\/(f)) => f.left
    case (-\/(e), \/-(b)) => e.left
    case (-\/(e), -\/(f)) => (e ++ f).left
  }
~~~

Let's use this new form with `readInt` and `sum2`. We'll start by writing a function that reads one argument and returns the

~~~ scala
merge(readInt("foo")) {
  merge(readInt("bar")) {
    (sum2 _).curried.right
  }
}
// Reading foo
// Reading bar
// res4: Result[Int] = -\/(List(Error reading foo, Error reading bar))
~~~

It's obvious that this code reads all of the lines from our file and accumulates all of the errors encountered. Let's pick apart at how it works:

 1. `(sum2 _).curried.right` creates a curried function and wraps it in a disjunction:

    ~~~ scala
    val inner = (sum2 _).curried.right[List[String]]
    // inner: Result[Int => (Int => Int)] = ...
    ~~~

    The result, `inner`, contains a curried function that accepts two `Int` parameters and adds them together. The type of `inner` is `Result[Int => (Int => Int)]`, which is of the form `Result[A => B]` required for `merge`.

 2. We pass `inner` to `merge` to produce a `Result[Int => Int]`:

    ~~~ scala
    val middle = merge(readInt("bar"))(inner)
    // middle: Result[Int => Int] = ...
    ~~~

    The result, `middle`, contains a curried function that accepts one `Int` parameter and adds it to the result read from `readInt("bar")`. The type is `Result[Int => Int]`, which again is of the form `Result[A => B]` required for `merge`.

 3. Finally, we pass `middle` to a second `merge` to produce a `Result[Int]`:

    ~~~ scala
    val outer = merge(readInt("foo"))(middle)
    // outer: Result[Int] = ...
    ~~~

In effect, this code curries `sum2` to produce a nested set of functions, and then peels each function off with a nested call to `merge`. The calls determine what arguments to inject and `merge` dictates how to combine the `Results` at each level of recursion. Naturally, this process generalises to functions of higher arity:

~~~ scala
def sum3(a: Int, b: Int, c: Int): Int =
  a + b + c

merge(readInt("foo")) {
  merge(readInt("bar")) {
    merge(readInt("baz")) {
      (sum3 _).curried.right
    }
  }
}
// Reading foo
// Reading bar
// Reading baz
// res5: Result[Int] = -\/(List(Error reading foo, ↩
//   Error reading bar, Error reading baz))
~~~
