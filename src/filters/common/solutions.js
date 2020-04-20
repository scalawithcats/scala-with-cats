const _ = require("underscore");
const pandoc = require("pandoc-filter");
const crypto = require("crypto");
const metadata = require("./metadata");

// String helpers --------------------------------

// arrayOf(node) -> string
function textOf(body) {
  let ans = "";

  for (let item of body) {
    switch (item.t) {
      case "Str":
        ans += item.c;
        break;

      case "Space":
        ans += " ";
        break;

      case "Emph":
        ans += textOf(item.c);
        break;

      case "Strong":
        ans += textOf(item.c);
        break;

      case "Span":
        ans += textOf(item.c);
        break;
    }
  }

  return ans;
}

// string integer -> string
function numberedTitle(title, number) {
  return number == null || number === 1 ? title : `${title} Part ${number}`;
}

// string string -> string
function stripPrefix(title, prefix) {
  return title.indexOf(prefix) === 0
    ? title.substring(prefix.length).trim()
    : title;
}

// string -> string
let labelCounter = 1;
function label(prefix, title) {
  try {
    return (
      prefix +
      crypto
        .createHash("md5")
        .update(title + "-" + labelCounter)
        .digest("hex")
    );
  } finally {
    labelCounter = labelCounter + 1;
  }
}

// Node helpers ----------------------------------

function solutionsHeading(text, level) {
  return pandoc.Header(level, ["solutions", [], []], [pandoc.Str(text)]);
}

function chapterHeading(heading, template, level) {
  return pandoc.Header(
    level,
    ["", [], []],
    [pandoc.Str(template.replace("$title", heading.title))]
  );
}

function solutionHeading(solution, template, level) {
  return pandoc.Header(
    level,
    [solution.solutionLabel, [], []],
    [
      pandoc.Str(
        template
          .replace("$title", solution.exerciseTitle)
          .replace(
            "$part",
            solution.exerciseNumber > 1 ? `Part ${solution.exerciseNumber}` : ""
          )
      ),
    ]
  );
}

function linkToSolution(solution) {
  return pandoc.Para([
    pandoc.Link(
      ["", [], []],
      [pandoc.Str("See the solution")],
      ["#" + solution.solutionLabel, ""]
    ),
  ]);
}

function linkToExercise(solution) {
  return pandoc.Para([
    pandoc.Link(
      ["", [], []],
      [pandoc.Str("Return to the exercise")],
      ["#" + solution.exerciseLabel, ""]
    ),
  ]);
}

// Data types ------------------------------------

class Heading {
  constructor(label, title) {
    this.label = label;
    this.title = title;
  }
}

class Solution {
  constructor(
    exerciseLabel,
    solutionLabel,
    exerciseTitle,
    exerciseNumber,
    body
  ) {
    this.exerciseLabel = exerciseLabel;
    this.solutionLabel = solutionLabel;
    this.exerciseTitle = exerciseTitle;
    this.exerciseNumber = exerciseNumber;
    this.body = body;
  }
}

function createFilter() {
  // Accumulators ----------------------------------

  // arrayOf(or(Heading, Solution))
  //
  // A list of chapter (level 1) headings and solutions:
  const solutionAccum = [];

  // or(Heading, null)
  //
  // The last heading (any level) we passed.
  // We record this because exercise titles are rendered using headings:
  let chapterAccum = null;
  let headingAccum = null;

  // integer
  //
  // The number of solutions we've passed since the last heading.
  // We record this because some exercises have multiple solutions:
  let chapterCounter = 0; // index of solution since last chapter heading
  let exerciseCounter = 0; // index of solution since last heading

  // Tree walkin' ----------------------------------

  return function (type, value, format, meta) {
    // Hacity hack. Don't generate links in print books:
    const createLinks = !meta.blackandwhiteprintable;

    switch (type) {
      case "Link": {
        const [attrs, body, [href, unused]] = value;

        return; // don't rewrite the document here
      }

      case "Header": {
        const [level, [ident, classes, kvs], body] = value;

        // Record the last title we passed so we can name and number exercises.
        // Some exercises have multiple solutions, so reset that counter too.
        headingAccum = new Heading(ident, textOf(body));
        exerciseCounter = 0;

        // We keep a record of the last chapter heading.
        // As soon as we see a solution in this chapter,
        // we add the chapter heading as a subheading in the solutions chapter:
        if (level === 1) {
          chapterAccum = headingAccum;
          chapterCounter = 0;
        }

        return; // don't rewrite the document here
      }

      case "Div":
        const [[ident, classes, kvs], body] = value;

        switch (classes && classes[0]) {
          case "solution": {
            chapterCounter = chapterCounter + 1;
            exerciseCounter = exerciseCounter + 1;

            // If this is the first solution this chapter,
            // push the chapter heading on the list of items to
            // render in the solutions chapter:
            if (chapterCounter === 1) {
              solutionAccum.push(chapterAccum);
            }

            // Titles of the exercise and the solution:
            const exerciseTitle = stripPrefix(headingAccum.title, "Exercise:");

            // Anchor labels for the exercise and the solution:
            const exerciseLabel = headingAccum.label;
            const solutionLabel = label("solution:", exerciseTitle);

            const solution = new Solution(
              exerciseLabel,
              solutionLabel,
              exerciseTitle,
              exerciseCounter,
              body
            );

            solutionAccum.push(solution);

            return createLinks ? linkToSolution(solution) : [];
          }

          case "solutions": {
            const solutionsHeadingText = metadata.getString(
              meta,
              ["solutions", "headingText"],
              undefined
            );

            const solutionsHeadingLevel = metadata.getInt(
              meta,
              ["solutions", "headingLevel"],
              1
            );

            const chapterHeadingTemplate = metadata.getString(
              meta,
              ["solutions", "chapterHeadingTemplate"],
              "$title"
            );

            const chapterHeadingLevel = metadata.getInt(
              meta,
              ["solutions", "chapterHeadingLevel"],
              2
            );

            const solutionHeadingTemplate = metadata.getString(
              meta,
              ["solutions", "solutionHeadingTemplate"],
              "Solution to: $title $part"
            );

            const solutionHeadingLevel = metadata.getInt(
              meta,
              ["solutions", "solutionHeadingLevel"],
              3
            );

            let nodes =
              solutionsHeadingText == null
                ? []
                : [
                    solutionsHeading(
                      solutionsHeadingText,
                      solutionsHeadingLevel
                    ),
                  ];

            for (let item of solutionAccum) {
              if (item instanceof Heading) {
                nodes = [
                  ...nodes,
                  chapterHeading(
                    item,
                    chapterHeadingTemplate,
                    chapterHeadingLevel
                  ),
                ];
              } else if (item instanceof Solution) {
                const link = createLinks ? [linkToExercise(item)] : [];

                nodes = [
                  ...nodes,
                  solutionHeading(
                    item,
                    solutionHeadingTemplate,
                    solutionHeadingLevel
                  ),
                  ...item.body,
                  ...link,
                ];
              }
            }

            return nodes;
          }
        }
    }
  };
}

module.exports = {
  createFilter,
};
