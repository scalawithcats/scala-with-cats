#!/usr/bin/env node

const unwrap = require("../common/unwrap-code");
const pandoc = require("pandoc-filter");

pandoc.stdio(unwrap.createFilter());
