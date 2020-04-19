import scala.sys.process._

name              in ThisBuild := "scala-with-cats"
organization      in ThisBuild := "io.underscore"
version           in ThisBuild := "0.0.1"

scalaVersion      in ThisBuild := "2.13.1"

useSuperShell     in ThisBuild := false
logLevel          in Global    := Level.Warn

val catsVersion = "2.0.0"

enablePlugins(MdocPlugin)
mdocIn  := sourceDirectory.value / "pages"
mdocOut := target.value          / "pages"

scalacOptions ++= Seq(
//   "-deprecation",
//   "-encoding", "UTF-8",
//   "-unchecked",
//   "-feature",
//   "-Xlint",
//   "-Xfatal-warnings",
//   "-Ywarn-dead-code",
  "-Yrepl-class-based"
)

// resolvers ++= Seq(Resolver.sonatypeRepo("snapshots"))

libraryDependencies ++= Seq("org.typelevel" %% "cats-core" % catsVersion)

addCompilerPlugin("org.typelevel" %% "kind-projector" % "0.11.0" cross CrossVersion.full)

mdocVariables := Map(
  "SCALA_VERSION" -> scalaVersion.value,
  "CATS_VERSION" -> catsVersion
)

lazy val pages = List(
  "intro/preface.md",
  "intro/versions.md",
  "intro/conventions.md",
  "intro/contributors.md",
  "intro/backers.md",

  "parts/part1.md",

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
  "applicatives/validated.md",
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

  "parts/part4.md",
)

lazy val pdfSetup  = taskKey[Unit]("Pre-mdoc component of the PDF build")
lazy val htmlSetup = taskKey[Unit]("Pre-mdoc component of the HTML build")
lazy val epubSetup = taskKey[Unit]("Pre-mdoc component of the ePub build")
lazy val jsonSetup = taskKey[Unit]("Pre-mdoc component of the JSON AST build")

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

jsonSetup := {
  "mkdir -p dist".!
}

lazy val pdfPandoc  = taskKey[Unit]("Pandoc component of the PDF build")
lazy val htmlPandoc = taskKey[Unit]("Pandoc component of the HTML build")
lazy val epubPandoc = taskKey[Unit]("Pandoc component of the ePub build")
lazy val jsonPandoc = taskKey[Unit]("Pandoc component of the JSON AST build")

pdfPandoc  := { Pandoc.commandLine(pages, PandocTarget.Pdf).! }
htmlPandoc := { Pandoc.commandLine(pages, PandocTarget.Html).! }
epubPandoc := { Pandoc.commandLine(pages, PandocTarget.Epub).! }
jsonPandoc := { Pandoc.commandLine(pages, PandocTarget.Json).! }

lazy val pdf  = taskKey[Unit]("Build the PDF version of the book")
lazy val html = taskKey[Unit]("Build the HTML version of the book")
lazy val epub = taskKey[Unit]("Build the ePub version of the book")
lazy val json = taskKey[Unit]("Build the Pandoc JSON AST of the book")

pdf  := {
  pdfSetup.value
  mdoc.toTask("").value
  pdfPandoc.value
}

html := {
  htmlSetup.value
  mdoc.toTask("").value
  htmlPandoc.value
}

epub := {
  epubSetup.value
  mdoc.toTask("").value
  epubPandoc.value
}

json := {
  jsonSetup.value
  mdoc.toTask("").value
  jsonPandoc.value
}

lazy val all  = taskKey[Unit]("Build all versions of the book")

all := {
  pdfSetup.value
  htmlSetup.value
  epubSetup.value

  mdoc.toTask("").value

  pdfPandoc.value
  htmlPandoc.value
  epubPandoc.value
}
