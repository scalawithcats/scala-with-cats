#!/usr/bin/env node

const _ = require("underscore");
const pandoc = require("pandoc-filter");

function action(type, value, format, meta) {
  if (type === "CodeBlock") {
    const [[ident, classes, kvs], body] = value;

    if (classes.includes("scala")) {
      return pandoc.RawBlock(
        "latex",
        ["\\begin{lstlisting}[style=scala]", body, "\\end{lstlisting}"].join(
          "\n"
        )
      );
    }
  }
}

pandoc.stdio(action);
