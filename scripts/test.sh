#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

printf 'Tool versions used for this run:\n'
node --version
npm --version
pnpm --version
dart --suppress-analytics --version
moon version
mooncake --version
scrut --version
git --version
printf '\n'
scrut test tests
