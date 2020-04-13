#!/bin/bash

set -euo pipefail

SUPPORTED_VERSIONS_REGEXP='^(latest|alpine|passenger|4)'
MAX_BUILDS_PER_RUN=10
REBUILD_PERIOD="1 week"
GFM_IMAGE_NAME=orchitech/redmine-gfm
GFM_IMAGE_BASE_URL=https://hub.docker.com/v2/repositories/$GFM_IMAGE_NAME
SOURCE_IMAGE_BASE_URL=https://hub.docker.com/v2/repositories/library/redmine

export TZ=UTC

_datecmd=date
command -v gdate >/dev/null 2>&1 && _datecmd=gdate
date()
{
  command "$_datecmd" "$@"
}

max() {
  printf "%s\n" "$@" | sort -r | head -n1
}

get_supported_versions()
{
  local next_page="$SOURCE_IMAGE_BASE_URL/tags?ordering=last_updated"
  local page
  local versions

  while [ "$next_page" != 'null' ]; do
    page=$(curl -sS "$next_page")
    versions+=$(echo "$page" | jq -r '.results[] | .name')$'\n'
    next_page=$(echo "$page" | jq -r '.next')
  done

  echo "$versions" | grep -E "$SUPPORTED_VERSIONS_REGEXP"
}

gfm_tag_exists()
{
  curl -f $GFM_IMAGE_BASE_URL/tags/$tag &> /dev/null
}

rebuild_since=$(date -d "-$REBUILD_PERIOD" -Is)
last_commit_date_local=$(git log -1 --date=iso-strict --format=%cd)
last_commit_date_utc=$(date -d "$last_commit_date_local" | date -Is)

builds=0
for tag in $(get_supported_versions); do
  if [ $builds -ge $MAX_BUILDS_PER_RUN ]; then
    break
  fi

  source_image_updated_on=$(curl -sS $SOURCE_IMAGE_BASE_URL/tags/$tag | jq -r '.last_updated')

  if gfm_tag_exists; then
    docker pull $GFM_IMAGE_NAME:$tag
    gfm_image_build_date=$(docker inspect $GFM_IMAGE_NAME:$tag | \
        jq -r '.[] | .Config | .Labels | .["build-date"] // empty')
  fi

  build_since=$(max "$source_image_updated_on" "$rebuild_since" "$last_commit_date_utc")
  if [[ -z "$gfm_image_build_date" || "$gfm_image_build_date" < "$build_since" ]]; then
    docker pull redmine:$tag
    echo "building $GFM_IMAGE_NAME:$tag..."
    docker build -t $GFM_IMAGE_NAME:$tag \
        --build-arg REDMINE_IMAGE=redmine:$tag \
        --build-arg BUILD_DATE="$(date -Is)" \
        --build-arg SOURCE_IMAGE_ID="$(docker inspect redmine:$tag | jq -r '.[] | .Id')" .
    docker push $GFM_IMAGE_NAME:$tag
    builds=$((builds + 1))
  fi
done
