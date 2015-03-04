## Validations

Scalaz provides two types for modelling error handling: `\/` and a new type called `Validation`. We've met `\/` already---it is a monad that provides fail-fast error handling semantics. In the following example, we never call `fail2` because `fail1` returns and error:

~~~ scala
type ErrorOr[A] = List[String] \/ A

def fail1: ErrorOr[Int] = {
  println("Calling fail1")
  List("Fail1").left
}

def fail2: ErrorOr[Int] = {
  println("Calling fail2")
  List("Fail2").left
}

Applicative[ErrorOr].apply2(fail1, fail2)(_ + _)
// Calling fail1
// res0: ErrorOr[Int] = -\/(Fail1)
~~~

Fail-fast is not always the correct type of error handling. Imagine validating a web form: we want to check all validation rules and return all errors we find, similar to the `ap_keepAll` method we defined in the last section.

Scalaz models this cumulative style of error handling with a different type called `Validation`. `Validation` is an `Applicative` (not a `Monad`) that accumulates errors on failure:

~~~ scala
type ErrorOr[A] = Validation[List[String], A]

def fail1: ErrorOr[String] = {
  println("Calling fail1")
  List("Fail1").failure
}

def fail2: ErrorOr[Int] = {
  println("Calling fail2")
  List("Fail2").failure
}

Applicative[ErrorOr].apply2(fail1, fail2)(_ + _)
// Calling fail2
// Calling fail1
// res1: ErrorOr[String] = Failure(List(Fail1, Fail2))
~~~

`Validation` uses a `Semigroup` to accumulate errors. Remember that a `Semigroup` is the `append` operation of a `Monoid` without the `zero` component:

~~~ scala
// Types of Validation:
type StringOr[A] = Validation[String, A]
type ListOr[A]   = Validation[List[String], A]
type VectorOr[A] = Validation[Vector[Int], A]

Applicative[StringOr].apply2("Hello".failure[Int], "world".failure[Int])(_ * _)
// res2: StringOr[Int] = Failure(Helloworld)

Applicative[ListOr].apply2(List("Hello").failure[Int], List("world").failure[Int])(_ * _)
// res3: ListOr[Int] = Failure(List(Hello, world))

Applicative[VectorOr].apply2(Vector(404).failure[Int], Vector(500).failure[Int])(_ * _)
// res4: VectorOr[Int] = Failure(Vector(404, 500))
~~~

### Validation Methods and Syntax

`Validation` has two subtypes, `Success` and `Failure`, that correspond loosely to the `Right` and `Left` subtypes of `Either`:

~~~ scala
import scalaz.{ Validation, Success, Failure }

val s: Validation[String, Int] = Success(123)
// s: scalaz.Validation[String,Int] = Success(123)

val f: Validation[String, Int] = Failure("message")
// f: scalaz.Validation[String,Int] = Failure(message)
~~~

We can import enriched `success` and `failure` methods from `scalaz.syntax.validation` to simplify construction:

~~~ scala
123.success[String]
// res5: scalaz.Validation[String,Int] = Success(123)

"message".failure[Int]
// res6: scalaz.Validation[String,Int] = Failure(message)
~~~

The enriched `parseInt` method we saw in exercises for `\/` is available from `scalaz.syntax.std.string`. It returns a `Validation[NumberFormatException, Int]`:

~~~ scala
"123".parseInt
// res7: scalaz.Validation[NumberFormatException,Int] = Success(123)
~~~

We can convert back and forth between `Validation` and `\/` using the `disjuction` and `validation` methods:

~~~ scala
"123".parseInt.disjunction
// res8: scalaz.\/[NumberFormatException,Int] = \/-(123)

"123".parseInt.disjunction.validation
// res9: scalaz.Validation[NumberFormatException,Int] = Success(123)
~~~

We can `map`, `leftMap`, and `biMap` to transform the success and failure values in a `Validation`, just as we can to transform the left and right values in a disjunction:

~~~ scala
123.success.map(_ * 100)
// res11: scalaz.Validation[Nothing,Int] = Success(12300)

456.failure.leftMap(_.toString)
// res12: scalaz.Validation[String,Nothing] = Failure(456)

123.success[String].bimap(_ + "!", _ * 100)
// res13: scalaz.Validation[String,Int] = Success(12300)

"fail".failure[Int].bimap(_ + "!", _ * 100)
// res14: scalaz.Validation[String,Int] = Failure(fail!)
~~~

Finally, we can `getOrElse` or `fold` on a `Validation` to extract the values:

~~~ scala
"fail".failure[Int].getOrElse(0)
// res15: Int = 0

"fail".failure[Int].fold(_ + "!!!", _.toString)
// res16: String = fail!!!
~~~

### Exercise: Form Validation

We want to validate an HTML registration form. We receive request data from the client in a `Map[String, String]` and want to parse it to create a `User` object:

~~~ scala
case class User(name: String, age: Int)
~~~

Our goal is to implement code that parses the incoming data enforcing the following rules:

 - the name and age must be specified;
 - the name must not be blank;
 - the the age must be a valid non-negative integer.

If all the rules pass our parser we should return a `User`. If any rules fail, we should return a `List` of the error messages.

Let's model this using the `Validation` data type. The first step is to determine an error type and write a type alias called `Result` to help us use `Validation` with `Applicative`:

<div class="solution">
The problem description specifies that we need to return a `List` of error messages in the event of a failure. `List[String]` is a sensible type to use to report errors.

We need to fix the error type for our `Validation` to create a type constructor with a single parameter that we can use with `Applicative`. We can do this with a simple type alias:

~~~ scala
type Result[A] = Validation[List[String], A]
~~~
</div>

Now define two methods to read the `"name"` and `"age"` fields:

 - `readName` should take a `Map[String, String]` parameter, extract the `"name"` field, check the relevant validation rules, and return a `Result[String]`;

 - `readAge` should take a `Map[String, String]` parameter, extract the `"age"` field, check the relevant validation rules, and return a `Result[Int]`.

Tip: Use the `parseInt` and `leftMap` methods described in the previous section to parse the age as an `Int`.

<div class="solution">
Here are the methods:

~~~ scala
def readName(data: Map[String, String]): Result[String] =
  data.get("name").map(_.trim) match {
    case None       => List("No name specified").failure
    case Some("")   => List("Name cannot be blank").failure
    case Some(name) => name.success
  }

def readAge(data: Map[String, String]): Result[Int] =
  data.get("age").map(_.trim) match {
    case None            => List("No age specified").failure
    case Some("")        => List("Age cannot be blank").failure
    case Some(ageString) => ageString.parseInt match {
      case Failure(exn)            => List("Age must be a number").failure
      case Success(num) if num < 0 => List("Age must not be negative").failure
      case Success(num)            => num.success
    }
  }
~~~
</div>

Finally, use an `Applicative` to combine the results of `readName` and `readAge` to produce a `User`:

<div class="solution">
There are several ways to do this. One option is to use `apply2`:

~~~ scala
def readUser(data: Map[String, String]): Result[User] =
  Applicative[Result].apply2(readName(data), readAge(data))(User.apply)

readUser(Map("name" -> "Dave", "age" -> "36"))
// res2: Result[User] = Success(User(Dave,36))

readUser(Map("age" -> "-1"))
// res3: Result[User] = Failure(List(No name specified, ↩
//   Age must not be negative))
~~~

Alternatively, we can use the applicative builder syntax for identical semantics but slightly shorter code:

~~~ scala
def readUser(data: Map[String, String]): Result[User] =
  (readName(data) |@| readAge(data))(User.apply)
~~~
</div>
