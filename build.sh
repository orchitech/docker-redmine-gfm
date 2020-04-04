#!/bin/bash

set -euo pipefail

SUPPORTED_VERSIONS_REGEXP='^(latest|alpine|passenger|4)'
REDMINE_GFM_IMAGE=orchitech/redmine-gfm

get_supported_versions()
{
  local next_page="https://hub.docker.com/v2/repositories/library/redmine/tags"
  local page
  local versions

  while [ "$next_page" != 'null' ]; do
    page=$(curl -sS "$next_page")
    versions+=$(echo "$page" | jq -r '.results[] | .name')$'\n'
    next_page=$(echo "$page" | jq -r '.next')
  done

  echo "$versions" | grep -E "$SUPPORTED_VERSIONS_REGEXP"
}

for tag in $(get_supported_versions); do
  echo "building $REDMINE_GFM_IMAGE:$tag..."
  docker build -t $REDMINE_GFM_IMAGE:$tag --build-arg REDMINE_IMAGE=redmine:$tag .
  docker push $REDMINE_GFM_IMAGE:$tag
done
