const pandoc = require("pandoc-filter");
const stdin = require("get-stdin");

// String helpers --------------------------------

// Newer versions of Pandoc output code listings as
// raw latex blocks containing lstlisting environments
// instead of as code blocks:
const listingBeginRegex = /^\\begin\{lstlisting\}\[style=([^\]]+)\]/;

const listingEndRegex = /\\end\{lstlisting\}$/;

function areMergeable(a, b) {
  if (a.t === "CodeBlock" && b.t === "CodeBlock") {
    // Merge CodeBlock-style blocks:
    const aLang = a.c[0][1][0] != null;
    const bLang = b.c[0][1][0] != null;
    return aLang === bLang;
  } else if (a.t === "RawBlock" && b.t === "RawBlock") {
    // Merge raw LaTeX blocks containing matching lstlisting environments:
    const aLang = a.c[1].match(listingBeginRegex);
    const bLang = b.c[1].match(listingBeginRegex);
    return (
      aLang != null &&
      bLang != null &&
      aLang.length >= 2 &&
      bLang.length >= 2 &&
      aLang[1] === bLang[1]
    );
  } else {
    return false;
  }
}

function mergeTwo(a, b) {
  // Merge CodeBlock-style blocks:
  if (a.t === "CodeBlock" && b.t === "CodeBlock") {
    return pandoc.CodeBlock(a.c[0], a.c[1] + "\n\n" + b.c[1]);
    // Merge raw LaTeX blocks containing matching lstlisting environments:
  } else if (a.t === "RawBlock" && b.t === "RawBlock") {
    return pandoc.CodeBlock(
      a.c[0],
      a.c[1].replace(listingBeginRegex, "") + b.c[1].replace(listingEndRegex)
    );
  } else {
    return false;
  }
}

function mergeAll(blocks, accum = []) {
  switch (blocks.length) {
    case 0:
      return accum;

    case 1:
      return accum.concat(blocks);

    default:
      const [a, b, ...tail] = blocks;
      return areMergeable(a, b)
        ? mergeAll([mergeTwo(a, b)].concat(tail), accum)
        : mergeAll([b].concat(tail), accum.concat([a]));
  }
}

function createFilter() {
  return function ({t: type, c: value}, format, meta) {
    switch (type) {
      case "Pandoc": {
        const [meta, blocks] = value;
        return { t: "Pandoc", c: [meta, mergeAll(blocks)] };
      }

      case "BlockQuote": {
        const blocks = value;
        return pandoc.BlockQuote(mergeAll(blocks));
      }

      case "Div": {
        const [attr, blocks] = value;
        return pandoc.Div(attr, mergeAll(blocks));
      }

      case "Note": {
        const blocks = value;
        return pandoc.Note(mergeAll(blocks));
      }

      case "ListItem": {
        const [blocks] = value;
        return pandoc.ListItem(mergeAll(blocks));
      }

      case "Definition": {
        const [blocks] = value;
        return pandoc.Definition(mergeAll(blocks));
      }

      case "TableCell": {
        const [blocks] = value;
        return pandoc.TableCell(mergeAll(blocks));
      }

      default: return value;
    }
  };
}

// Rewrite of pandoc.stdio that
// treats the top-level Pandoc as a single element
// so we can merge code blocks at the top level -.-
function stdioComplete(action) {
  return stdin((json) => {
    let data = JSON.parse(json);
    data = Object.assign(data, { blocks: mergeAll(data.blocks) });
    const format = process.argv.length > 2 ? process.argv[2] : "";
    const output = pandoc.filter(data, action, format);
    process.stdout.write(JSON.stringify(output));
  });
}

module.exports = {
  createFilter,
  stdioComplete,
};
