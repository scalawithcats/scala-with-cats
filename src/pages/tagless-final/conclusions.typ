#import "../stdlib.typ": info, warning, solution
== Conclusions


In this chapter we looked at codata interpreters, and their extension to tagless final. Tagless final is particularly interesting because it solves the expression problem, allowing us to extend both the operations a program can perform and the interpretations of that program.

Our exploration of tagless final nicely illustrates the distinction between theory and craft introduced in @sec:intro:three-levels. We saw two different encoding of tagless final in Scala (three, if we count using context bounds as a different encoding). They are both tagless final at the theory level, but are very different to implement or use as a programmer. The "standard" encoding is relatively easy to implement for the library author, but tedious and potentially confusing for the user. The improved encoding places more work on the library author, but the user writes code in a natural style.

Tagless final is very powerful and it can be tempting to use it everywhere. I want to caution against this urge. Tagless final can cause problems, both for the author and the user. From the user's point of view everything works fine until they make a mistake. Then the errors can be confusing. Consider this code, where we have missed a parameter to `and`.

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

The error message _does_ tell us the problem, but it exposes a lot of the internal machinery that the user is not normally exposed to, and hence they'll probably have difficult understanding. A straightforward data or codata interpreter does not have this problem.

From the library author's point of view, it is a lot more work to create tagless final code. It can also be difficult to onboard new developers to this code, as the techniques are not familiar to most.

As always, the applicability of tagless final comes down to the context in which it is used. In cases where the extensibility is truly justified it is a powerful tool. In other cases it just introduces unwarranted complexity.

The term "expression problem" was first introduced in an email by Phil Wadler @wadler98:ep, but there are much earlier sources that discuss the same issue. (One example is #cite(<cook90:oo-adt>, form: "prose").) Tagless final was first introduced in #cite(<jacques09:finally-tagless>, form: "prose") and expanded on in #cite(<kiselyov12:tagless-final>, form: "prose"). It is just one of many solutions that have been proposed to the expression problem. I'm no expert on the wider field of solutions to the expression problem, but of the papers I've read the ones I'd like to highlight are object algebras @oliveira12:object-algebras and data types à la carte @swierstra08:data-types. Object algebras are, in all essentials, the same as tagless final. They were developed in object-oriented languages rather than functional programming languages, making an interesting case of convergent evolution in two distinct, but connected, fields of research. The object algebras paper is also a good read for a more formal, if brief, discussion of the theory behind the concepts we've been dealing with. Data types à la carte is a data, rather than codata, approach to the expression problem, and so makes an interesting contrast to tagless final. I find tagless final much simpler, so we have not explored data types à la carte in this book. Another noteworthy paper is #cite(<gibbons14:folding>, form: "prose"), which discuss the duality between data and codata and its implication for embedded domain specific languages.

Tagless final was introduced using Haskell as the implementation language. The standard encoding in Scala is a direct translation of the Haskell implementation. The improved Scala encoding is my own creation. The use of the single abstract method shortcut was suggested by Jakub Kozłowski.
