## Versions

This book is written for Scala 2.12.x and Cats 1.0.0-MF.
Here is a minimal `built.sbt` containing
the relevant dependencies and settings[^sbt-version]:

```scala
scalaVersion := "2.12.3"

libraryDependencies += "org.typelevel" %% "cats-core" % "1.0.0-MF"

scalacOptions ++= Seq(
  "-Xfatal-warnings",
  "-Ypartial-unification"
)
```

[^sbt-version]: We assume you are using SBT 0.13.13 or newer.

### Template Projects

For convenience, we have created a Giter8 template to get you started.
To clone the template type the following:

```bash
$ sbt new underscoreio/cats-seed.g8
```

This will generate a minimal project
with a single file for you to edit.

If you prefer a more batteries-included starting point,
we recommend Typelevel's `sbt-catalysts` template:

```bash
$ sbt new typelevel/sbt-catalysts.g8
```

This will generate a project with a suite of Typelevel
library dependencies and compiler plugins,
together with templates for unit tests
and [tut-enabled][link-tut] documentation.
See the project pages for [catalysts][link-catalysts]
and [sbt-catalysts][link-sbt-catalysts]
for more information.
