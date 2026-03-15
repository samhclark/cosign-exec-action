#!/bin/sh
# ABOUTME: Entrypoint for cosign GitHub Action. Runs cosign with provided args,
# optionally iterating each line from the EACH input, substituting {} in ARGS.

set -e

if [ -n "${INPUT_EACH}" ]; then
    printf '%s\n' "${INPUT_EACH}" | while read -r line; do
        interpolated=$(printf '%s' "${INPUT_ARGS}" | sed "s|{}|${line}|g")
        # shellcheck disable=SC2086
        cosign $interpolated
    done
else
    # shellcheck disable=SC2086
    cosign ${INPUT_ARGS}
fi
