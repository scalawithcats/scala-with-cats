#!/usr/bin/env node

const merge = require("../common/merge-code");
const pandoc = require("pandoc-filter");

merge.stdioComplete(merge.createFilter());
