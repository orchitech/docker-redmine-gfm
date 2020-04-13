#!/bin/bash

set -euo pipefail

help()
{
  echo "Usage:"
  echo " REDMINE_DIRECTORY PATCH_DIRECTORY REDMINE_VERSION"
}

if [[ $# -ne 3 ]]; then
  help >&2
  exit 1
fi

redmine_dir=$1
patch_dir=$2
redmine_version=$3

cd "$patch_dir"
for d in */ ; do
  version_from=$(echo "$d" | cut -d- -f1)
  version_to=$(echo "$d" | cut -d- -f2 | cut -d/ -f1)

  versions=$(printf "%s\n%s\n%s" "$version_from" "$redmine_version" "$version_to" | sed '/^$/d')
  versions_sorted=$(echo "$versions" | sort -V)

  if [ "$versions" = "$versions_sorted" ]; then
    cat "$d"/*.patch | patch -p1 -d "$redmine_dir"
  fi
done
