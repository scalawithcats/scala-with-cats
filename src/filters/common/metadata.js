const _ = require("underscore");
const pandoc = require("pandoc-filter");

function getString(meta, key, orElse = undefined) {
  function stringify(node) {
    if (Array.isArray(node)) {
      return node.map(stringify).join("");
    } else if (node != null && node.t != null) {
      switch (node.t) {
        case "Space":
          return " ";
        default:
          return stringify(node.c);
      }
    } else if (node != null) {
      return `${node}`;
    } else {
      return orElse;
    }
  }

  function ref(node, key) {
    if (key.length === 0) {
      return stringify(node);
    } else {
      const [head, ...tail] = key;
      switch (node && node.t) {
        case "MetaMap":
        case "MetaList":
          return ref(node.c[head], tail);

        case "MetaBool":
        case "MetaString":
        case "MetaInlines":
        case "MetaBlocks":
        default:
          return orElse;
      }
    }
  }

  return key.length === 0 ? stringify(meta) : ref(meta[key[0]], key.slice(1));
}

function getInt(meta, key, orElse = undefined) {
  const str = getString(meta, key, undefined);
  return str == null ? orElse : parseInt(str, 10);
}

module.exports = {
  getString,
  getInt,
};
