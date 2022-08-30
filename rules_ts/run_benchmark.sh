#!/usr/bin/env bash
set -o errexit -o nounset

style=$1
results_file=${2:-"$PWD/results"}

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

./generate.sh "$style"

bazel_flags=()
if [[ "$style" == *"sandboxed_worker"* ]]; then
  bazel_flags+=( --worker_sandboxing )
else
  bazel_flags+=( --noworker_sandboxing )
fi

if [[ "$style" == *"rbe"* ]]; then
  bazel_flags+=( --config=rbe )
fi

# if [[ "${CI:-}" ]]; then
#   bazel_flags+=( --config=ci )
# fi

pushd "$style"
if [ "$style" == "tsc" ]; then
  yarn install
  measure "$results_file" "${style}__clean_build" ../node_modules/.bin/tsc --build --verbose --incremental
  echo 'console.log()' >> "billing/lib0/cmp0/cmp0.component.ts"
  measure "$results_file" "${style}__incremental_build" ../node_modules/.bin/tsc --build --verbose --incremental
else
  bazel fetch ...
  bazel clean
  measure "$results_file" "${style}__clean_build" bazel build "${bazel_flags[@]}" ...
  echo 'console.log()' >> "billing/lib0/cmp0/cmp0.component.ts"
  measure "$results_file" "${style}__incremental_build" bazel build "${bazel_flags[@]}" ...
  bazel clean
  measure "$results_file" "${style}__transpile" bazel build "${bazel_flags[@]}" :devserver
  echo 'console.log()' >> "billing/lib0/cmp0/cmp0.component.ts"
  measure "$results_file" "${style}__incremental_transpile" bazel build "${bazel_flags[@]}" :devserver
  measure "$results_file" "${style}__typecheck" bazel build "${bazel_flags[@]}" ...
  echo 'console.log()' >> "billing/lib0/cmp0/cmp0.component.ts"
  measure "$results_file" "${style}__incremental_typecheck" bazel build "${bazel_flags[@]}" ...
fi
popd
