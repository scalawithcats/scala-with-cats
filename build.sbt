import scala.sys.process._
import sbt.nio._
import sbt.nio.file.FileTreeView
import sbt.nio.Keys._
import sbt.io.IO
import sbt.Keys.streams
import java.io.File

ThisBuild / organization := "com.scalawithcats"
ThisBuild / version := "0.0.1"

ThisBuild / scalaVersion := "3.3.6"

ThisBuild / useSuperShell := false
Global / onChangedBuildSource := ReloadOnSourceChanges
Global / logLevel := Level.Info

val catsVersion = "2.13.0"
val doodleVersion = "0.30.0"

libraryDependencies ++= Seq(
  "org.typelevel" %% "cats-core" % catsVersion,
  "org.creativescala" %% "doodle" % doodleVersion,
  "org.scalameta" %% "munit" % "0.7.29" % Test,
  "org.scalameta" %% "munit-scalacheck" % "0.7.29" % Test
)

mdocVariables := Map(
  "SCALA_VERSION" -> scalaVersion.value,
  "CATS_VERSION" -> catsVersion
)

def copyWithNewExtension(
    glob: Glob,
    src: File,
    dst: File,
    ext: String
): Seq[File] = {
  val sources =
    FileTreeView.default
      .list(glob)
      .collect { case (file, _) => file.toFile }
      .pair(Path.rebase(src, dst))
      .map { case (src, dst) =>
        src -> Path(
          s"${dst.getParent()}${File.separator}${dst.base}.${ext}"
        ).asFile
      }
  IO.copy(sources).toSeq
}

val pagesDirectory = settingKey[File](
  "The top of the directory tree that contains the book source."
)
pagesDirectory := sourceDirectory.value / "pages"

val pages = settingKey[Glob]("The source files for the book.")
pages := pagesDirectory.value.toGlob / ** / "*.typ"

val mdDirectory = settingKey[File](
  "The top of the directory tree into which md files are generated."
)
mdDirectory := (baseDirectory.value / "target" / "md")

val typstToMd = taskKey[Seq[File]]("Copy the typst files to md for mdoc.")
typstToMd := {
  streams.value.log.info("Copying typst files to md")
  copyWithNewExtension(
    pages.value,
    pagesDirectory.value,
    mdDirectory.value,
    "md"
  )
}

enablePlugins(MdocPlugin)
mdocIn := mdDirectory.value
mdocOut := target.value / "mdOut"

val typstDirectory = settingKey[File](
  "The top of the directory tree into which the mdoc processed typst files are generated."
)
typstDirectory := baseDirectory.value / "target" / "pages"

val mdToTypst = taskKey[Seq[File]]("Copy the mdoc processed md files to typst.")
mdToTypst := {
  streams.value.log.info("Copying md files to typst")
  val glob = mdocOut.value.toGlob / ** / "*.md"
  copyWithNewExtension(glob, mdocOut.value, typstDirectory.value, "typ")
}

val copyNonTypstFiles =
  taskKey[Seq[File]]("Copy non-md files to the typst build.")
copyNonTypstFiles := {
  streams.value.log.info("Copying non-md files to typst")
  val sources = FileTreeView.default
    .list(pagesDirectory.value.toGlob / ** / "*.{svg,png,bib}")
    .collect { case (file, _) => file.toFile }
    .pair(Path.rebase(pagesDirectory.value, typstDirectory.value))
  IO.copy(sources).toSeq
}

val outputDirectory = settingKey[File]("Path where the built book goes.")
outputDirectory := baseDirectory.value / "dist"

val pdfFile = settingKey[File]("The PDF book file name.")
pdfFile := outputDirectory.value / "functional-programming-strategies.pdf"

val typst = taskKey[File]("Build the book using Typst.")
typst := {
  streams.value.log.info("Running typst")
  s"typst compile ${typstDirectory.value}/fps.typ ${pdfFile.value}".!
  pdfFile.value
}

val build =
  taskKey[File]("Build the book, returning the path to the output.")
build / fileInputs += pages.value
build := Def
  .sequential(
    typstToMd,
    mdoc.toTask(""),
    mdToTypst,
    copyNonTypstFiles,
    typst
  )
  .value
