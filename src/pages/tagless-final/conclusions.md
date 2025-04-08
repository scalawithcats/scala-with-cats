## Conclusions

In this chapter we looked at codata interpreters, and their extension to tagless final. Tagless final is particularly interesting because it solves the expression problem, allowing us to extend both the operations a program can perform and the interpretations of that program.

Tagless final is very powerful, and we've seen an encoding of it in Scala that allows the user to write code in a very natural style. As a result it can be tempting to use it everywhere. I want to caution against this urge. Tagless final can cause problems, both for the author and the user. From the user's point of view everything works fine until they make a mistake. Then the errors can be confusing. Consider this code, where we have missed a parameter to `and`.

```scala mdoc:invisible
type Validation[A] = A => Either[String, A]

// The validation rule that always succeeds
def succeed[A](value: A): Either[String, A] = Right(value)
trait Algebra {
  type Ui[_]
}
trait Controls extends Algebra {
  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Ui[String]

  def choice[A](label: String, options: Seq[(String, A)]): Ui[A]
}
trait Layout extends Algebra {
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}
trait Program[-Alg <: Algebra, A] {
  def apply(alg: Alg): alg.Ui[A]
}
object Controls {
  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Program[Controls, String] =
    alg => alg.textInput(label, placeholder, validation)

  def choice[A](
    label: String, 
    options: Seq[(String, A)]
  ): Program[Controls, A] =
    alg => alg.choice(label, options)
}
extension [Alg <: Algebra, A](p: Program[Alg, A]) {
  def and[Alg2 <: Algebra, B](
    second: Program[Alg2, B]
  ): Program[Alg & Alg2 & Layout, (A, B)] =
    alg => alg.and(p(alg), second(alg))
}
```


```scala mdoc:fail
Controls.textInput("Name", "John Doe").and()
```

The error message *does* tell us the problem, but it exposes a lot of the internal machinery that the user is not normally exposed so and hence they'll probably have a hard time understanding. A straightforward data or codata interpreter does not have this problem.

From the library author's point of view, it is a lot more work to create tagless final code. It can also be difficult to onboard new developers to this code, as the techniques are not familiar to most.

As always, the applicability of tagless final comes down to the context in which it is used. In cases where the extensibility is truly justified it is a powerful tool. In other cases it just introduces unwarranted complexity.

The term "expression problem" was first introduced in an email by Phil Wadler [@wadler98:ep], but there are much earlier sources that discuss the same issue. [@cook90:oo-adt] is one example. Tagless final is just one of many solutions that have been proposed to the expression problem. It was first introduced in [@jacques09:finally-tagless] and expanded on in [@kiselyov12:tagless-final]. Haskell is used as the implementation language. The common encoding in Scala is a direct translation of the Haskell implementation. The improved Scala encoding is my own creation. The use of the single abstract method shortcut was suggested by Jakub Kozłowski.
