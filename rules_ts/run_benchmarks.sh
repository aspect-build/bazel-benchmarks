#!/usr/bin/env bash
set -o errexit -o nounset

results_file="$PWD/results"
rm -f "$results_file"

styles=(
    'ts_project'
    'ts_project_rbe'
    'ts_project_worker'
    'ts_project_sandboxed_worker'
    'ts_project_swc'
    'ts_project_swc_rbe'
    'ts_project_worker_swc'
    'ts_project_sandboxed_worker_swc'
    'ts_project_rules_nodejs'
    'ts_project_rules_nodejs_swc'
    'ts_library'
    'ts_library_rbe'
    'tsc'
)

for style in "${styles[@]}"
do
    ./run_benchmark.sh "$style" "$results_file"
done

# sort the results
sort "$results_file" -o "$results_file"

echo "========================================"
cat "$results_file"
