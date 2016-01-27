lazy val root = project.in(file("."))
  .settings(tutSettings)

tutSourceDirectory := sourceDirectory.value / "raw"

tutTargetDirectory := sourceDirectory.value / "pages"

scalaVersion := "2.11.7"

scalacOptions ++= Seq(
  "-deprecation",
  "-encoding", "UTF-8",
  "-unchecked",
  "-feature",
  "-Ywarn-dead-code",
  "-Xlint",
  "-Xfatal-warnings"
)

resolvers ++= Seq(Resolver.sonatypeRepo("snapshots"))

libraryDependencies ++= Seq(
  "org.scalaz" %% "scalaz-core" % "7.1.3",
  "org.spire-math" %% "cats" % "0.4.0-SNAPSHOT"
)

lazy val pdf = taskKey[Unit]("Builds the PDF version of the book")

pdf := {
  val a = tut.value
  "grunt pdf" !
}


