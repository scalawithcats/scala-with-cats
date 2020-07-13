const _ = require("underscore");
const pandoc = require("pandoc-filter");

/*
This script strips the object/import pattern
needed to emulate Scala's :paste mode in Tut:

```scala
object wrapper {

}; import wrapper._
```
*/

const emptyRegex = /^\s*(?:\/[\/*].*)?$/;
const openingRegex = /^\s*object\s+([a-zA-Z0-9_]+)\s*\{[\r\n]*/;
const closingRegex = /[\r\n]*\}[\s;]+import\s*([a-zA-Z0-9_]+)\._\s*$/;

function unindentBy(line, indent) {
  // If there are at least that many whitespaces at the start...
  if (line.substring(0, indent).trim().length === 0) {
    return line.substring(indent, line.length);
  } else {
    console.error(`Can't unindent "${line}" by ${indent} spaces.`);
    return line;
  }
}

// Detects how many spaces this line is indented by:
function indentSize(line) {
  const match = line.match(/[^\s]/);
  return match == null ? 0 : match.index;
}

function unindent(text) {
  const lines = text.split("\n");

  const indent = _.chain(lines)
    .filter((l) => !emptyRegex.test(l))
    .map((l) => indentSize(l))
    .min()
    .value();

  return lines.map((l) => unindentBy(l, indent)).join("\n");
}

function createFilter() {
  return function filter(type, value, format, meta) {
    if (type !== "CodeBlock") {
      return;
    }

    const [[ident, classes, kvs], body] = value;

    if (classes.includes("scala")) {
      return;
    }

    const openingMatch = body.match(openingRegex);
    const closingMatch = body.match(closingRegex);

    if (
      openingMatch == null ||
      closingMatch == null ||
      openingMatch[1] !== closingMatch[1]
    ) {
      return;
    }

    return pandoc.CodeBlock(
      [ident, classes, kvs],
      unindent(body.replace(openingRegex, "").replace(closingRegex, ""))
    );
  };
}

module.exports = {
  createFilter,
};
