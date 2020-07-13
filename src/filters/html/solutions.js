#!/usr/bin/env node

const _ = require("underscore");
const pandoc = require("pandoc-filter");

pandoc.stdio(function (type, value, format, meta) {
  switch (type) {
    case "Header": {
      const [level, [ident, classes, kvs], body] = value;

      // Remove "solutions" heading from the document:
      return ident === "solutions" ? [] : undefined;
    }
    case "Div": {
      const [[ident, classes, kvs], body] = value;

      // Remove "solutions" div from the document:
      return classes != null && classes[0] === "solutions" ? [] : undefined;
    }
  }
});
