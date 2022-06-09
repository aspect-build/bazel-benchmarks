################################################################################
# 4. Lazy fetching and linking
################################################################################

# Start with ✔ Populated cache, ✔ Lock file, ✗ node_modules and
# run the "uuid" CLI tool

# npm
# ✔ Populated npm cache
# ✔ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="4_npm"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_install
  echo "setup..."
  rm -rf node_modules
  record "$results_file" "__${perf}_npm_version" `npm --version`
  # --legacy-peer-deps needed to get past peer deps failures
  # setting --offline leads to failures
  measure "$results_file" "$perf" \
    npm install --legacy-peer-deps
  # we can now run uuid cli
  ./node_modules/.bin/uuid
  cd -
fi

# npm_install
# ✔ Populated npm cache
# ✔ Lock file
# ✗ node_modules (in npm_install external repository)
# ------------------------------------------------------------------------------
if true; then
  perf="4_npm_install"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_install
  echo "setup..."
  bazel clean --expunge && rm -rf node_modules
  record "$results_file" "__${perf}_npm_version" `bazel run @nodejs_darwin_amd64//:bin/npm -- --version`
  measure "$results_file" "$perf" \
    bazel run //:uuid_bin
  cd -
fi

# yarn
# ✔ Populated yarn cache
# ✔ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="4_yarn"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd yarn_install
  echo "setup..."
  rm -f snapshots.js && rm -rf node_modules
  record "$results_file" "__${perf}_npm_version" `yarn --version`
  # setting --immutable-cache leads to failure if we also delete the lock file
  measure "$results_file" "$perf" \
    yarn install
  # we can now run uuid cli
  ./node_modules/.bin/uuid
  cd -
fi

# yarn_install
# ✔ Populated yarn cache
# ✔ Lock file
# ✗ node_modules (in yarn_install external repository)
# ------------------------------------------------------------------------------
if true; then
  perf="4_yarn_install"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd yarn_install
  echo "setup..."
  bazel clean --expunge && rm -rf node_modules
  record "$results_file" "__${perf}_yarn_version" `bazel run @yarn//:yarn -- --version`
  # setting --immutable-cache leads to failure if we also delete the lock file
  measure "$results_file" "$perf" \
    bazel run //:uuid_bin
  cd -
fi

# pnpm install
# ✔ Populated CAS
# ✔ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="4_pnpm"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_translate_lock
  echo "setup..."
  rm -rf node_modules
  record "$results_file" "__${perf}_pnpm_version" `pnpm --version`
  # --strict-peer-dependencies=false needed to get past peer deps failures
  measure "$results_file" "$perf" \
    pnpm install --offline --strict-peer-dependencies=false
  # we can now run uuid cli
  ./node_modules/.bin/uuid
  cd -
fi

# npm_translate_lock
# ✔ Populated CAS
# ✔ Lock file
# ✗ node_modules (in bazel output tree)
# ------------------------------------------------------------------------------
if true; then
  perf="4_npm_translate_lock_cached"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_translate_lock
  echo "setup..."
  bazel clean && rm -rf node_modules
  bazel fetch //...
  bazel query @npm//...
  bazel query @local_config_cc_toolchains//...
  bazel query @local_config_platform//...
  bazel query @local_config_sh//...
  bazel query @local_jdk//...
  bazel run @nodejs_darwin_amd64//:bin/node -- --version
  measure "$results_file" "$perf" \
    bazel run //:uuid_bin
  cd -
fi
