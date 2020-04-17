#!/bin/bash

set -euo pipefail

REBUILD_PERIOD="1 week"
GFM_IMAGE_NAME=orchitech/redmine-gfm

export TZ=UTC
source .version

_datecmd=date
command -v gdate >/dev/null 2>&1 && _datecmd=gdate
date()
{
  command "$_datecmd" "$@"
}

_grepcmd=grep
command -v ggrep >/dev/null 2>&1 && _grepcmd=ggrep
grep()
{
  command "$_grepcmd" "$@"
}

fail()
{
  echo "$1" >&2
  exit 1
}

gfm_tag_exists()
{
  curl -f "https://hub.docker.com/v2/repositories/$GFM_IMAGE_NAME/tags/$TAG" &> /dev/null
}

get_gfm_label()
{
  local label=$1
  docker inspect "$GFM_IMAGE_NAME:$TAG" | jq -r ".[] | .Config | .Labels | .[\"$label\"] // empty"
}

get_gfm_last_updated()
{
  date -d $(curl -sS "https://hub.docker.com/v2/repositories/$GFM_IMAGE_NAME/tags/$TAG" | jq -r ".last_updated") --utc +%FT%TZ
}

need_rebuild()
{
  if gfm_tag_exists; then
    docker pull "$GFM_IMAGE_NAME:$TAG"

    local gfm_image_from_digest=$(get_gfm_label "from-image-digest")
    if [ "$gfm_image_from_digest" != "$FROM_IMAGE_DIGEST" ]; then
      echo "The current $GFM_IMAGE_NAME $TAG tag's from image digest $gfm_image_from_digest does not match the source image digest $from_image_digest." >&2
      return 0
    fi
    local gfm_image_version=$(get_gfm_label "redmine-gfm-version")
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
  docker pull "redmine@$FROM_IMAGE_DIGEST"
  docker build -t "$GFM_IMAGE_NAME:$TAG" \
      --build-arg REDMINE_IMAGE="redmine:$TAG" \
      --build-arg FROM_IMAGE_DIGEST="$FROM_IMAGE_DIGEST" \
      --build-arg REDMINE_GFM_VERSION="$VERSION" .
  docker push "$GFM_IMAGE_NAME:$TAG"
fi
