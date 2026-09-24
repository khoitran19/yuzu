#!/usr/bin/env bash
# Formats Swift sources in place; pass --lint to check only.
set -euo pipefail
cd "$(dirname "$0")/.."
paths=(App Modules Tools Project.swift)
if [[ "${1:-}" == "--lint" ]]; then
  swift format lint --recursive --parallel "${paths[@]}"
else
  swift format --in-place --recursive --parallel "${paths[@]}"
fi
