#!/usr/bin/env node

const solutions = require("../common/solutions");
const pandoc = require("pandoc-filter");

pandoc.stdio(solutions.createFilter());
