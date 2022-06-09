################################################################################
# 1. Lockfile generation / dependency resolution
################################################################################

# npm install
# ✗ Populated npm cache
# ✗ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="1_npm"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_install
  echo "setup..."
  rm -f package-lock.json && npm cache clean --force && rm -rf node_modules
  record "$results_file" "__${perf}_npm_version" `npm ---version`
  # --legacy-peer-deps needed to get past peer deps failures
  measure "$results_file" "$perf" \
    npm install --legacy-peer-deps
  cd -
fi

# npm install
# ✔ Populated npm cache
# ✗ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="1_npm_cached"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_install
  echo "setup..."
  rm -f package-lock.json && rm -rf node_modules
  record "$results_file" "__${perf}_npm_version" `npm ---version`
  # --legacy-peer-deps needed to get past peer deps failures
  # setting --offline leads to failures
  measure "$results_file" "$perf" \
    npm install --legacy-peer-deps
  cd -
fi

# yarn install (node_module linker)
# ✗ Populated yarn cache
# ✗ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="1_yarn"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd yarn_install
  echo "setup..."
  rm -f yarn.lock && yarn cache clean --all && rm -f snapshots.js && rm -rf node_modules
  record "$results_file" "__${perf}_yarn_version" `yarn --version`
  measure "$results_file" "$perf" \
    yarn install
  cd -
fi

# yarn install (node_module linker)
# ✔ Populated yarn cache
# ✗ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="1_yarn_cached"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd yarn_install
  echo "setup..."
  rm -f yarn.lock && rm -f snapshots.js && rm -rf node_modules
  record "$results_file" "__${perf}_yarn_version" `yarn --version`
  # setting --immutable-cache leads to failure if we also delete the lock file
  measure "$results_file" "$perf" \
    yarn install
  cd -
fi

# pnpm install
# ✗ Populated CAS
# ✗ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="1_pnpm"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_translate_lock
  echo "setup..."
  rm -f pnpm-lock.yaml && rm -rf $(pnpm store path) && rm -rf node_modules
  record "$results_file" "__${perf}_pnpm_version" `pnpm --version`
  # --strict-peer-dependencies=false needed to get past peer deps failures
  measure "$results_file" "$perf" \
    pnpm install --lockfile-only --strict-peer-dependencies=false
  cd -
fi

# pnpm install
# ✔ Populated CAS
# ✗ Lock file
# ✗ node_modules
# ------------------------------------------------------------------------------
if true; then
  perf="1_pnpm_cached"
  echo -e "\n\n\n================================================================================\n$perf"
  echo "================================================================================"
  cd npm_translate_lock
  echo "setup..."
  rm -f pnpm-lock.yaml && rm -rf node_modules
  record "$results_file" "__${perf}_pnpm_version" `pnpm --version`
  # --strict-peer-dependencies=false needed to get past peer deps failures
  measure "$results_file" "$perf" \
    pnpm install --lockfile-only --offline --strict-peer-dependencies=false
  cd -
fi
