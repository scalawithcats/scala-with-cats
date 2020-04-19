#!/usr/bin/env node

const images = require("../common/vector-images");
const pandoc = require("pandoc-filter");

pandoc.stdio(images.createFilter("svg"));
