sealed abstract class PandocTarget extends Product with Serializable

object PandocTarget {
  case object Tex extends PandocTarget
  case object Pdf extends PandocTarget
  case object Html extends PandocTarget
  case object Epub extends PandocTarget
  case object Json extends PandocTarget
  case object Typst extends PandocTarget
}

object Pandoc {

  /** Create the command-line options without `pandoc` command */
  def commandLineOptions(
      pages: List[String],
      target: PandocTarget,
      usePandocCrossref: Boolean = true,
      usePandocInclude: Boolean = true,
      filenameStem: String = "functional-programming-strategies",
      pagesDir: String = "target/pages",
      srcDir: String = "src",
      distDir: String = "dist",
      tocDepth: Int = 2
  ): String = {
    import PandocTarget._

    val relPages = pages.map(page => s"${pagesDir}/${page}")

    val output = target match {
      case Tex   => s"--output=${distDir}/${filenameStem}.tex"
      case Pdf   => s"--output=${distDir}/${filenameStem}.pdf"
      case Html  => s"--output=${distDir}/${filenameStem}.html"
      case Epub  => s"--output=${distDir}/${filenameStem}.epub"
      case Json  => s"--output=${distDir}/${filenameStem}.json"
      case Typst => s"--output=${distDir}/${filenameStem}.pdf"
    }

    val template = target match {
      case Pdf | Tex => Some(s"--template=${srcDir}/templates/template.tex")
      case Html      => Some(s"--template=${srcDir}/templates/template.html")
      case Epub  => Some(s"--template=${srcDir}/templates/template.epub.html")
      case Typst => Some(s"--template=${srcDir}/templates/template.typst")
      case Json  => None
    }

    val filters = target match {
      case Pdf | Tex | Json =>
        List(
          s"--filter=pandoc-crossref",
          s"--filter=${srcDir}/filters/pdf/unwrap-code.js",
          // s"--filter=${srcDir}/filters/pdf/merge-code.js",
          s"--filter=${srcDir}/filters/pdf/callout.js",
          s"--filter=${srcDir}/filters/pdf/columns.js",
          s"--filter=${srcDir}/filters/pdf/solutions.js",
          s"--lua-filter=${srcDir}/filters/pdf/vector-images.lua",
          s"--filter=${srcDir}/filters/pdf/listings.js"
        )
      case Typst =>
        List(
          s"--filter=pandoc-crossref",
          s"--filter=${srcDir}/filters/pdf/unwrap-code.js",
          // s"--filter=${srcDir}/filters/pdf/merge-code.js",
          s"--filter=${srcDir}/filters/pdf/callout.js",
          s"--filter=${srcDir}/filters/pdf/columns.js",
          s"--filter=${srcDir}/filters/pdf/solutions.js",
          s"--lua-filter=${srcDir}/filters/html/vector-images.lua",
          s"--filter=${srcDir}/filters/pdf/listings.js"
        )
      case Html =>
        List(
          s"--filter=pandoc-crossref",
          s"--filter=${srcDir}/filters/html/unwrap-code.js",
          // s"--filter=${srcDir}/filters/html/merge-code.js",
          s"--filter=${srcDir}/filters/html/tables.js",
          s"--filter=${srcDir}/filters/html/solutions.js",
          s"--lua-filter=${srcDir}/filters/html/vector-images.lua"
        )
      case Epub =>
        List(
          s"--filter=pandoc-crossref",
          s"--filter=${srcDir}/filters/epub/unwrap-code.js",
          // s"--filter=${srcDir}/filters/epub/merge-code.js",
          s"--filter=${srcDir}/filters/epub/solutions.js",
          s"--lua-filter=${srcDir}/filters/epub/vector-images.lua"
        )
    }

    val extras = target match {
      case Pdf | Tex =>
        List(
          s"--toc-depth=${tocDepth}",
          s"--listings",
          s"--include-before-body=${srcDir}/templates/cover-notes.tex",
          s"--pdf-engine=typst"
        )
      case Typst =>
        List(
          s"--toc-depth=${tocDepth}",
          s"--listings",
          s"--pdf-engine=typst"
        )
      case Html =>
        List(
          s"--toc-depth=${tocDepth}",
          s"--include-before-body=${srcDir}/templates/cover-notes.html"
        )
      case Epub =>
        List(
          s"--toc-depth=${tocDepth}",
          s"--css=${srcDir}/temp/epub.css",
          s"--epub-cover-image=${srcDir}/covers/epub-cover.png",
          s"--include-before-body=${srcDir}/templates/cover-notes.html"
        )
      case Json =>
        Nil
    }

    val metadata = target match {
      case Pdf | Tex =>
        List(s"${srcDir}/meta/metadata.yaml", s"${srcDir}/meta/pdf.yaml")
      case Html =>
        List(s"${srcDir}/meta/metadata.yaml", s"${srcDir}/meta/html.yaml")
      case Epub =>
        List(s"${srcDir}/meta/metadata.yaml", s"${srcDir}/meta/epub.yaml")
      case Json | Typst => List(s"${srcDir}/meta/metadata.yaml")
    }

    val options =
      List(
        List(output),
        template.toList,
        List(
          "--from=markdown+grid_tables+multiline_tables+fenced_code_blocks+fenced_code_attributes+yaml_metadata_block+implicit_figures+header_attributes+definition_lists+link_attributes+citations",
          s"--variable=lib-dir:${srcDir}"
        ),
        filters,
        List(
          "--top-level-division=chapter",
          "--number-sections",
          "--table-of-contents",
          "--highlight-style tango",
          "--standalone",
          "--embed-resources",
          "--citeproc"
        ),
        extras,
        metadata,
        relPages
      ).flatten

    options.mkString(" ")
  }

  def commandLine(
      pages: List[String],
      target: PandocTarget,
      usePandocCrossref: Boolean = true,
      usePandocInclude: Boolean = true,
      filenameStem: String = "functional-programming-strategies",
      pagesDir: String = "target/pages",
      srcDir: String = "src",
      distDir: String = "dist",
      tocDepth: Int = 3
  ): String = {

    s"pandoc ${commandLineOptions(pages, target, usePandocCrossref, usePandocInclude, filenameStem, pagesDir, srcDir, distDir, tocDepth)}"
  }
}
