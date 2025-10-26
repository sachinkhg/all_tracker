#!/usr/bin/env bash
set -euo pipefail

# Run Flutter tests with coverage and print a short summary.

flutter test --coverage

echo "\nCoverage lcov file at coverage/lcov.info"
if command -v genhtml >/dev/null 2>&1; then
  genhtml coverage/lcov.info -o coverage/html >/dev/null 2>&1 || true
  echo "HTML report (if genhtml available): coverage/html/index.html"
else
  echo "Install lcov (genhtml) to generate an HTML report."
fi


