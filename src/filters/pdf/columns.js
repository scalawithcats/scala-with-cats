#!/usr/bin/env node

const _ = require("underscore");
const pandoc = require("pandoc-filter");

function action({t: type, c: value}, format, meta) {
  if (type === "Div") {
    const [[ident, classes, kvs], body] = value;

    switch (classes && classes[0]) {
      case "row":
        const [head, ...tail] = body;

        var tailWithSeps = _.chain(tail)
          .map((col) => [pandoc.RawBlock("latex", "\\columnbreak"), col])
          .flatten()
          .value();

        return pandoc.Div(
          [ident, [], kvs],
          [
            pandoc.RawBlock("latex", `\\begin{multicols}{${body.length}}`),
            head,
            ...tailWithSeps,
            pandoc.RawBlock("latex", "\\end{multicols}"),
          ]
        );
    }
  }
}

pandoc.stdio(action);
