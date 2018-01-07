## Versions {-}

This book is written for Scala 2.12.3 and Cats 1.0.0.
Here is a minimal `build.sbt` containing
the relevant dependencies and settings[^sbt-version]:

```scala
scalaVersion := "2.12.3"

libraryDependencies +=
  "org.typelevel" %% "cats-core" % "1.0.0"

scalacOptions ++= Seq(
  "-Xfatal-warnings",
  "-Ypartial-unification"
)
```

[^sbt-version]: We assume you are using SBT 0.13.13 or newer.

### Template Projects {-}

For convenience, we have created
a Giter8 template to get you started.
To clone the template type the following:

```bash
$ sbt new underscoreio/cats-seed.g8
```

This will generate a sandbox project
with Cats as a dependency.
See the generated `README.md` for
instructions on how to run the sample code
and/or start an interactive Scala console.

The `cats-seed` template is as minimal as it gets.
If you'd prefer a more batteries-included starting point,
check out Typelevel's `sbt-catalysts` template:

```bash
$ sbt new typelevel/sbt-catalysts.g8
```

This will generate a project with a suite
of library dependencies and compiler plugins,
together with templates for unit tests
and [tut-enabled][link-tut] documentation.
See the project pages for [catalysts][link-catalysts]
and [sbt-catalysts][link-sbt-catalysts]
for more information.
