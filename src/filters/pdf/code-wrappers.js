#!/usr/bin/env node

const _ = require("underscore");
const pandoc = require("pandoc-filter");

function action(type, value, format, meta) {
  switch (type) {
    case "CodeBlock":
      const [[ident, classes, kvs], body] = value;

      if (classes.includes("scala")) {
        return pandoc.CodeBlock([ident, classes, kvs], body);
      }
  }
}

pandoc.stdio(action);
