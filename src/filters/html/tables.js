#!/usr/bin/env node

const _ = require("underscore");
const pandoc = require("pandoc-filter");

// Because we wrap the table we're processing in a <div>,
// the walk algorithm causes us to revisit when processing
// the children of the <div>. We "hash" (stringify) visited
// tables and cache them here to prevent infinite recursion.
const visited = [];

function action(type, value, format, meta) {
  if (type === "Table") {
    const hash = JSON.stringify(value);

    if (!_.contains(visited, hash)) {
      visited.push(hash);
      return pandoc.Div(
        ["", ["table-responsive"], []],
        [pandoc.Table.apply(this, value)]
      );
    }
  }
}

pandoc.stdio(action);
