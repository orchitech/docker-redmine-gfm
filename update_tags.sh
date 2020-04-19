#!/bin/bash

set -euo pipefail

SUPPORTED_VERSIONS_REGEXP='^(latest|alpine|passenger|4)'

get_docker_hub_token()
{
  curl -sS --user "$DOCKER_HUB_USERNAME:$DOCKER_HUB_PASSWORD" \
      "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/redmine:pull" | jq -r '.token'
}

# Image digests from https://hub.docker.com/v2/repositories/library/redmine/tags are
# unfortunately unusable. See https://github.com/docker/hub-feedback/issues/1925,
# `docker manifest inspect --verbose redmine:tag` and the command docs for more info
get_image_digest()
{
  local tag=$1
  curl -sS "https://registry-1.docker.io/v2/library/redmine/manifests/$tag" \
      -H "Authorization:Bearer $(get_docker_hub_token)" \
      -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" | \
      jq -r '.manifests[] | select(.platform.os == "linux" and .platform.architecture == "amd64") | .digest'
}

get_supported_tags()
{
  local next_page="https://hub.docker.com/v2/repositories/library/redmine/tags?ordering=last_updated"
  local page
  local versions

  while [ "$next_page" != 'null' ]; do
    page=$(curl -sS "$next_page")
    versions+=$(echo "$page" | jq -r '.results[] | . as $result | .images[] | select(.os == "linux" and .architecture == "amd64") | $result.name')$'\n'

    next_page=$(echo "$page" | jq -r '.next')
  done

  echo "$versions" | grep -E "$SUPPORTED_VERSIONS_REGEXP"
}

if [ -z "${DOCKER_HUB_USERNAME-}" ]; then
  echo "DOCKER_HUB_USERNAME environment variable must be set." >&2
  exit 1
fi

if [ -z "${DOCKER_HUB_PASSWORD-}" ]; then
  echo "DOCKER_HUB_PASSWORD environment variable must be set." >&2
  exit 1
fi

echo "env:" > tags.yml
for tag in $(get_supported_tags); do
  echo "  - TAG=$tag FROM_IMAGE_DIGEST=$(get_image_digest $tag)" >> tags.yml
done
