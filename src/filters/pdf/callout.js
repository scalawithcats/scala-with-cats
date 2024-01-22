const pandoc = require("pandoc-filter");

function action({t: type, c: value}, format, meta) {
  if (type === "Div") {
    const [[ident, classes, kvs], body] = value;

    switch (classes && classes[0]) {
      case "callout":
        const environmentName =
          classes[1] === "callout-danger"
            ? "DangerCallout"
            : classes[1] === "callout-warning"
            ? "WarningCallout"
            : "InfoCallout";

        return pandoc.Div(
          [ident, [], kvs],
          [
            pandoc.RawBlock("latex", `\\begin{${environmentName}}`),
            ...body,
            pandoc.RawBlock("latex", `\\end{${environmentName}}`),
          ]
        );
    }
  }
}

pandoc.stdio(action);
