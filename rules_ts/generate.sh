#!/usr/bin/env bash
set -o errexit -o nounset

style=$1

rm -rf "$style"
node generator.js "$style" "$style" 3 10 10 1000
