#!/bin/bash

set -euo pipefail

SUPPORTED_VERSIONS_REGEXP='(latest|alpine|passenger|4)'

get_tags()
{
  local next_page="https://hub.docker.com/v2/repositories/library/redmine/tags?ordering=last_updated"
  local page
  local versions

  while [ "$next_page" != 'null' ]; do
    page=$(curl -sS "$next_page")
    versions+=$(echo "$page" | jq -r '.results[] | . as $result | .images[] | select(.os == "linux" and .architecture == "amd64") | "TAG=" + $result.name + " FROM_IMAGE_DIGEST=" + .digest')$'\n'

    next_page=$(echo "$page" | jq -r '.next')
  done

  echo "$versions" | grep -E "^TAG=$SUPPORTED_VERSIONS_REGEXP"
}

echo "env:" > tags.yml
get_tags | sed 's/^/  - /' >> tags.yml
