#!/bin/bash

set -eu -o pipefail

cd "$(dirname "$0")"
source "./common.sh"

REBUILD_PERIOD="1 week"

source .version

get_gfm_labels()
{
  local tag=$1
  local token=$(get_docker_hub_token $GFM_IMAGE_NAME)
  local config_digest=$(curl -sS "$DOCKER_HUB_REGISTRY_URL/v2/$GFM_IMAGE_NAME/manifests/$tag" \
      -H "Authorization:Bearer $token" \
      -H "Accept: application/vnd.docker.distribution.manifest.v2+json" | \
      jq -r .config.digest)
  curl -sS -L --max-redirs 3 "$DOCKER_HUB_REGISTRY_URL/v2/$GFM_IMAGE_NAME/blobs/$config_digest" \
      -H "Authorization:Bearer $token" | \
      jq -r .container_config.Labels
}

gfm_tag_exists()
{
  curl -f "https://hub.docker.com/v2/repositories/$GFM_IMAGE_NAME/tags/$TAG" &> /dev/null
}

get_gfm_last_updated()
{
  date -d $(curl -sS "https://hub.docker.com/v2/repositories/$GFM_IMAGE_NAME/tags/$TAG" | jq -r ".last_updated") --utc +%FT%TZ
}

need_rebuild()
{
  if gfm_tag_exists; then
    local gfm_image_labels=$(get_gfm_labels "$TAG")
    local gfm_image_from_digest=$(jq -r '.["from-image-digest"]' <<< "$gfm_image_labels")
    if [ "$gfm_image_from_digest" != "$FROM_IMAGE_DIGEST" ]; then
      echo "The current $GFM_IMAGE_NAME $TAG tag's from image digest $gfm_image_from_digest does not match the source image digest $FROM_IMAGE_DIGEST." >&2
      return 0
    fi
    local gfm_image_version=$(jq -r '.["redmine-gfm-version"]' <<< "$gfm_image_labels")
    if [ "$gfm_image_version" != "$VERSION" ]; then
      echo "The current $GFM_IMAGE_NAME $TAG tag's version $gfm_image_version does not match the current version $VERSION." >&2
      return 0
    fi
    local rebuild_since=$(date -d "-$REBUILD_PERIOD" --utc +%FT%TZ)
    if [[ "$(get_gfm_last_updated)" < "$rebuild_since" ]]; then
      echo "The current $GFM_IMAGE_NAME:$TAG is too old." >&2
    fi
    return 1
  else
    echo "Redmine GFM image with tag $TAG does not exist" >&2
    return 0
  fi
}

if [ -z "${TAG-}" ]; then
  fail "TAG environment variable must be set."
fi
if [ -z "${FROM_IMAGE_DIGEST-}" ]; then
  fail "FROM_IMAGE_DIGEST environment variable must be set."
fi

if need_rebuild; then
  echo "building $GFM_IMAGE_NAME:$TAG..." >&2
  case "$TAG" in
    alpine|*-alpine|*-alpine-*)
      linux_distribution=alpine ;;
    *)
      linux_distribution=debian ;;
  esac
  docker build -t "$GFM_IMAGE_NAME:$TAG" \
      --build-arg FROM_IMAGE_DIGEST="$FROM_IMAGE_DIGEST" \
      --build-arg LINUX_DISTRIBUTION="$linux_distribution" \
      --build-arg REDMINE_GFM_VERSION="$VERSION" .
  docker push "$GFM_IMAGE_NAME:$TAG"
fi
