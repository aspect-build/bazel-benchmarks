################################################################################
# 3. Incremental node_modules linking
################################################################################

# Make a dependency upgrade to test incremental install
# chai@3.5.0 => chai@4.3.6

# Undo benchmark_3 changes from prior runs
git checkout npm_install/package.json
git checkout npm_translate_lock/package.json
git checkout yarn_install/package.json

# npm
# ✔ Populated npm cache
# ✔ Lock file
# ✔ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="3_npm"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_install
  echo "setup..."
  npm install --legacy-peer-deps
  sedi 's#"chai": "3.5.0"#"chai": "4.3.6"#' package.json
  git diff package.json
  record "$results_file" "__${perf}_npm_version" `npm --version`
  # --legacy-peer-deps needed to get past peer deps failures
  measure "$results_file" "$perf" \
    npm install --legacy-peer-deps
  echo "cleanup"
  git checkout .
  cd -
fi

# npm_install
# ✔ Populated npm cache
# ✔ Lock file
# ✔ node_modules (in npm_install external repository)
# ------------------------------------------------------------------------------
if true; then
  perf="3_npm_install"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_install
  echo "setup..."
  bazel query @npm//...
  sedi 's#"chai": "3.5.0"#"chai": "4.3.6"#' package.json
  git diff package.json
  # update lock file
  npm install --legacy-peer-deps
  record "$results_file" "__${perf}_npm_version" `bazel run @nodejs_darwin_amd64//:bin/npm -- --version`
  measure "$results_file" "$perf" \
    bazel query @npm//...
  echo "cleanup"
  git checkout .
  cd -
fi

# yarn
# ✔ Populated yarn cache
# ✔ Lock file
# ✔ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="3_yarn"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd yarn_install
  echo "setup..."
  yarn install
  sedi 's#"chai": "3.5.0"#"chai": "4.3.6"#' package.json
  git diff package.json
  record "$results_file" "__${perf}_npm_version" `yarn --version`
  measure "$results_file" "$perf" \
    yarn install
  echo "cleanup"
  git checkout .
  cd -
fi

# yarn_install
# ✔ Populated yarn cache
# ✔ Lock file
# ✔ node_modules (in yarn_install external repository)
# ------------------------------------------------------------------------------
if true; then
  perf="3_yarn_install"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd yarn_install
  echo "setup..."
  bazel query @npm//...
  sedi 's#"chai": "3.5.0"#"chai": "4.3.6"#' package.json
  git diff package.json
  # update lock file
  yarn install
  measure "$results_file" "$perf" \
    bazel query @npm//...
  echo "cleanup"
  git checkout .
  cd -
fi

# pnpm install
# ✔ Populated CAS
# ✔ Lock file
# ✔ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="3_pnpm"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_translate_lock
  echo "setup..."
  pnpm install --strict-peer-dependencies=false
  sedi 's#"chai": "3.5.0"#"chai": "4.3.6"#' package.json
  git diff package.json
  # --strict-peer-dependencies=false needed to get past peer deps failures
  measure "$results_file" "$perf" \
    pnpm install --strict-peer-dependencies=false
  echo "cleanup"
  git checkout .
  cd -
fi

# npm_translate_lock
# ✔ Populated external repositories & external repository cache
# ✔ Lock file
# ✔ node_modules (in bazel output tree)
# ------------------------------------------------------------------------------
if true; then
  perf="3_npm_translate_lock"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_translate_lock
  echo "setup..."
  bazel build //...
  sedi 's#"chai": "3.5.0"#"chai": "4.3.6"#' package.json
  git diff package.json
  # update lock file
  pnpm install --lockfile-only --strict-peer-dependencies=false
  measure "$results_file" "$perf" \
    bazel build //...
  echo "cleanup"
  git checkout .
  cd -
fi
