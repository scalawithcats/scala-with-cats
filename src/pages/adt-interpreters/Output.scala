enum Output[A] {
  case Print(value: String) extends Output[Unit]
  case Newline() extends Output[Unit]
  case FlatMap[A, B](source: Output[A], f: A => Output[B]) extends Output[B]
  case Value(a: A)

  def andThen[B](that: Output[B]): Output[B] =
    this.flatMap(_ => that)

  def flatMap[B](f: A => Output[B]): Output[B] =
    FlatMap(this, f)

  def run(): A =
    this match {
      case Print(value)       => print(value)
      case Newline()          => println()
      case FlatMap(source, f) => f(source.run()).run()
      case Value(a)           => a
    }
}
object Output {
  def print(value: String): Output[Unit] =
    Print(value)

  def newline: Output[Unit] =
    Newline()

  def println(value: String): Output[Unit] =
    print(value).andThen(newline)

  def value[A](a: A): Output[A] =
    Value(a)
}

val hello = Output.println("Hello")
val helloHello = hello.andThen(" ,").andThen(hello).andThen("?")
// hello.andThen(hello).run()

def oddOrEven(phrase: String): Output[Unit] =
  Output
    .value(phrase % 2 == 0)
    .flatMap(even =>
      if even then Output.print(s"$phrase has an even number of letters.")
      else Output.print(s"$phrase has an odd number of letters.")
    )
