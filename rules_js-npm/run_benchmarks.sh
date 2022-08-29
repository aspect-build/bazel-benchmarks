#!/usr/bin/env bash
set -o errexit -o nounset

# Portable python3-based function to get milli-second precision time since `date +%s.%N`
# does not work on OSX time which doesn't doesn't support %N
function millis() {
  python3 -c 'from time import time; print(int(round(time() * 1000)))'
}

function measure() {
  local perf_file="$1"
  shift
  local perf_name="$1"
  shift
  start=`millis`
  echo "+" "$@"
  "$@"
  end=`millis`
  runtime_ms="$((end-start))"
  runtime=`echo "scale=2 ; $runtime_ms / 1000" | bc`
  record "$perf_file" "$perf_name" "$runtime"
}

record() {
  local perf_file="$1"
  shift
  local perf_name="$1"
  shift
  local perf_value="$@"
  printf "%s %s\n" "$perf_name" "$perf_value"
  printf "%s %s\n" "$perf_name" "$perf_value" >> "$perf_file"
}

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
sedi () {
  case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi='-i' ;;
  esac

  sed "${sedi[@]}" "$@"
}

results_file="$PWD/results"
rm -f "$results_file"

cd npm_install
record "$results_file" "bazel_version" `bazel --version`
cd -

# Undo benchmark_3 changes from prior runs
git checkout npm_install/package.json
git checkout npm_translate_lock/package.json
git checkout yarn_install/package.json

source ./benchmark_1.sh
source ./benchmark_2.sh
source ./benchmark_3.sh
source ./benchmark_4.sh

# Undo benchmark_3 local changes
git checkout npm_install/package.json
git checkout npm_translate_lock/package.json
git checkout yarn_install/package.json

# sort the results
cat "$results_file" | sort > "$results_file"

echo "========================================"
cat "$results_file"
