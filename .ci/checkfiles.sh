#!/bin/bash

find Core -type f -name "*.qs" -exec ./.ci/checkfile.sh {} \;
find Patches -type f -name "*.qs" -exec ./.ci/checkfile.sh {} \;
find Patches -type f -name "*.txt" -exec ./.ci/checkfile.sh {} \;
find Addons -type f -name "*.qs" -exec ./.ci/checkfile.sh {} \;
find Input -type f -name "*.txt" -exec ./.ci/checkfile.sh {} \;

export DATA=$(git diff)
if [[ -n "${DATA}" ]]; then
    echo "Found wrong end lines or BOM chars in files"
    git diff
    exit 1
fi
