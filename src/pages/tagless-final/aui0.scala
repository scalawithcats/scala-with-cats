//> using dep org.typelevel::cats-core:2.13.0
//
import cats.syntax.all.*
import scala.io.StdIn
import scala.util.Try

type Validation[A] = A => Either[String, A]

// The validation rule that always succeeds
def succeed[A](value: A): Either[String, A] = Right(value)

trait Controls[Ui[_]] {
  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Ui[String]

  def choice[A](label: String, options: Seq[(String, A)]): Ui[A]
}

trait Layout[Ui[_]] {
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}

type Program[A] = () => A

object Simple extends Controls[Program], Layout[Program] {
  def and[A, B](first: Program[A], second: Program[B]): Program[(A, B)] =
    (first, second).tupled

  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Program[String] =
    () => {
      def loop(): String = {
        println(s"$label (e.g. $placeholder):")
        val input = StdIn.readLine

        validation(input).fold(
          msg => {
            println(msg)
            loop()
          },
          value => value
        )
      }

      loop()
    }

  def choice[A](label: String, options: Seq[(String, A)]): Program[A] =
    () => {
      def loop(): A = {
        println(label)
        options.zipWithIndex.foreach { case ((desc, _), idx) =>
          println(s"$idx: $desc")
        }

        Try(StdIn.readInt).fold(
          _ => {
            println("Please enter a valid number.")
            loop()
          },
          idx => {
            if idx >= 0 && idx < options.size then options(idx)(1)
            else {
              println("Please enter a valid number.")
              loop()
            }
          }
        )
      }

      loop()
    }
}

@main def example(): Unit = {
  def bio[Ui[_]](
      controls: Controls[Ui],
      layout: Layout[Ui]
  ): Ui[(String, Int)] =
    layout.and(
      controls.textInput("What is your name?", "John Doe"),
      controls.choice(
        "How many years have you been using Scala?",
        Seq("0-2" -> 0, "3-5" -> 3, "5-7" -> 5, "8+" -> 8)
      )
    )

  def quiz[Ui[_]](
      controls: Controls[Ui],
      layout: Layout[Ui]
  ): Ui[(String, Int)] =
    layout.and(
      controls.textInput("What is your name?", "John Doe"),
      controls.choice(
        "Tagless final is the greatest thing ever",
        Seq(
          "Strongly disagree" -> 1,
          "Disagree" -> 2,
          "Neutral" -> 3,
          "Agree" -> 4,
          "Strongly agree" -> 5
        )
      )
    )

  val (name, rating) = quiz(Simple, Simple)()
  println(s"Hello $name!")
  println(s"You gave tagless final a rating of $rating.")
}
