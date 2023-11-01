import scala.sys.process._

ThisBuild / name := "scala-with-cats"
ThisBuild / organization := "com.scalawithcats"
ThisBuild / version := "0.0.1"

ThisBuild / scalaVersion := "3.3.1"

ThisBuild / useSuperShell := false
Global / logLevel := Level.Warn

enablePlugins(MdocPlugin)
mdocIn := sourceDirectory.value / "pages"
mdocOut := target.value / "pages"

val catsVersion = "2.9.0"

libraryDependencies ++= Seq("org.typelevel" %% "cats-core" % catsVersion)

// addCompilerPlugin("org.typelevel" % "kind-projector" % "0.13.2" cross CrossVersion.full)

scalacOptions += "-Ykind-projector:underscores"

mdocVariables := Map(
  "SCALA_VERSION" -> scalaVersion.value,
  "CATS_VERSION" -> catsVersion
)

lazy val pages = List(
  "preface/preface.md",
  "preface/versions.md",
  "preface/conventions.md",
  "preface/contributors.md",
  "preface/backers.md",
  "intro/index.md",
  "intro/three-levels.md",
  "intro/what-is-fp.md",
  "parts/part1.md",
  "adt/index.md",
  "adt/scala.md",
  "adt/structural-recursion.md",
  "adt/structural-corecursion.md",
  "adt/applications.md",
  "adt/algebra.md",
  "adt/conclusions.md",
  "adt-interpreters/index.md",
  "adt-interpreters/regexp.md",
  "adt-interpreters/reification.md",
  "adt-interpreters/tail-recursion.md",
  "adt-interpreters/effects.md",
  "type-classes/index.md",
  "type-classes/anatomy.md",
  "type-classes/implicits.md",
  "type-classes/printable.md",
  "type-classes/cats.md",
  "type-classes/equal.md",
  "type-classes/instance-selection.md",
  "type-classes/summary.md",
  "monoids/index.md",
  "monoids/cats.md",
  "monoids/applications.md",
  "monoids/summary.md",
  "functors/index.md",
  "functors/cats.md",
  "functors/contravariant-invariant.md",
  "functors/contravariant-invariant-cats.md",
  "functors/partial-unification.md",
  "functors/summary.md",
  "monads/index.md",
  "monads/cats.md",
  "monads/id.md",
  "monads/either.md",
  "monads/monad-error.md",
  "monads/eval.md",
  "monads/writer.md",
  "monads/reader.md",
  "monads/state.md",
  "monads/custom-instances.md",
  "monads/summary.md",
  "monad-transformers/index.md",
  "monad-transformers/summary.md",
  "applicatives/index.md",
  "applicatives/semigroupal.md",
  "applicatives/examples.md",
  "applicatives/parallel.md",
  "applicatives/applicative.md",
  "applicatives/summary.md",
  "foldable-traverse/index.md",
  "foldable-traverse/foldable.md",
  "foldable-traverse/foldable-cats.md",
  "foldable-traverse/traverse.md",
  "foldable-traverse/traverse-cats.md",
  "foldable-traverse/summary.md",
  "parts/part2.md",
  "case-studies/testing/index.md",
  "case-studies/map-reduce/index.md",
  "case-studies/validation/index.md",
  "case-studies/validation/sketch.md",
  "case-studies/validation/check.md",
  "case-studies/validation/map.md",
  "case-studies/validation/kleisli.md",
  "case-studies/validation/conclusions.md",
  "case-studies/crdt/index.md",
  "case-studies/crdt/eventual-consistency.md",
  "case-studies/crdt/g-counter.md",
  "case-studies/crdt/generalisation.md",
  "case-studies/crdt/abstraction.md",
  "case-studies/crdt/summary.md",

  // "case-studies/parser/index.md",
  // "case-studies/parser/intro.md",
  // "case-studies/parser/error-handling.md",
  // "case-studies/parser/transforms.md",
  // "case-studies/parser/applicative.md",

  "parts/part3.md",
  "solutions.md",
  "links.md",
  "parts/part4.md"
)

/*

The code below outlines steps to build the book:

Each build is independent (even the TeX and PDF builds).
The PDF, HTML, and ePub builds are the important ones.
Others are for debugging.

Each build involves three steps: a setup step, mdoc, and a Pandoc step.
You can run each of these steps indepdendently. For example,
running `pdf` is equivalent to `;pdfSetup; mdoc; pdfPandoc`.

The `all` task is equivalent to `;pdf ;html ;epub`,
except that it only runs `mdoc` once.

The code to build the Pandoc command-line is in `project/Pandoc.scala`.

 */

lazy val pdfSetup = taskKey[Unit]("Pre-mdoc component of the PDF build")
lazy val htmlSetup = taskKey[Unit]("Pre-mdoc component of the HTML build")
lazy val epubSetup = taskKey[Unit]("Pre-mdoc component of the ePub build")

lazy val texSetup = taskKey[Unit]("Pre-mdoc component of the TeX debug build")
lazy val jsonSetup =
  taskKey[Unit]("Pre-mdoc component of the JSON AST debug build")

pdfSetup := {
  "mkdir -p dist".!
}

htmlSetup := {
  "mkdir -p dist src/temp".!
  "npm install".!
  "npx lessc --include-path=node_modules --strict-imports src/less/html.less src/temp/html.css".!
  "npx browserify src/js/html.js --outfile src/temp/html.js".!
}

epubSetup := {
  "mkdir -p dist src/temp".!
  "npm install".!
  "npx lessc --include-path=node_modules --strict-imports src/less/epub.less src/temp/epub.css".!
}

texSetup := {
  "mkdir -p dist".!
}

jsonSetup := {
  "mkdir -p dist".!
}

lazy val pdfPandoc = taskKey[String]("Pandoc command-line for the PDF build")
lazy val htmlPandoc = taskKey[String]("Pandoc command-line for the HTML build")
lazy val epubPandoc = taskKey[String]("Pandoc command-line for the ePub build")

lazy val texPandoc =
  taskKey[String]("Pandoc command-line for the TeX debug build")
lazy val jsonPandoc =
  taskKey[String]("Pandoc command-line for the JSON AST debug build")

pdfPandoc := { Pandoc.commandLineOptions(pages, PandocTarget.Pdf) }
htmlPandoc := { Pandoc.commandLineOptions(pages, PandocTarget.Html) }
epubPandoc := { Pandoc.commandLineOptions(pages, PandocTarget.Epub) }

texPandoc := { Pandoc.commandLineOptions(pages, PandocTarget.Tex) }
jsonPandoc := { Pandoc.commandLineOptions(pages, PandocTarget.Json) }

lazy val pdf = taskKey[Unit]("Build the PDF version of the book")
lazy val html = taskKey[Unit]("Build the HTML version of the book")
lazy val epub = taskKey[Unit]("Build the ePub version of the book")

lazy val tex = taskKey[Unit]("Build the TeX debug build of the book")
lazy val json = taskKey[Unit]("Build the JSON AST debug build of the book")

pdf := {
  val cmdLineOptions =
    Def.sequential(pdfSetup, mdoc.toTask(""), pdfPandoc).value
  val cmd = s"pandoc $cmdLineOptions"
  println(cmd)
  streams.value.log.info(cmd)
  cmd.!
}

html := {
  val cmdLineOptions =
    Def.sequential(htmlSetup, mdoc.toTask(""), htmlPandoc).value
  val cmd = s"pandoc $cmdLineOptions"
  streams.value.log.info(cmd)
  cmd.!
}

epub := {
  val cmdLineOptions =
    Def.sequential(epubSetup, mdoc.toTask(""), epubPandoc).value
  val cmd = s"pandoc $cmdLineOptions"
  streams.value.log.info(cmd)
  cmd.!
}

tex := {
  val cmdLineOptions =
    Def.sequential(texSetup, mdoc.toTask(""), texPandoc).value
  val cmd = s"pandoc $cmdLineOptions"
  streams.value.log.info(cmd)
  cmd.!
}

json := {
  val cmdLineOptions =
    Def.sequential(jsonSetup, mdoc.toTask(""), jsonPandoc).value
  val cmd = s"pandoc $cmdLineOptions"
  streams.value.log.info(cmd)
  cmd.!
}

lazy val all =
  taskKey[Unit]("Build the PDF, HTML, and ePub versions of the book")

all := {
  pdf.value
  html.value
  epub.value
}
