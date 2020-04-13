#!/bin/bash

set -euo pipefail

SUPPORTED_VERSIONS_REGEXP='^(latest|alpine|passenger|4)'
REDMINE_GFM_IMAGE=orchitech/redmine-gfm
MAX_BUILDS_PER_RUN=10
REBUILD_PERIOD="1 week"

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
  local next_page="https://hub.docker.com/v2/repositories/library/redmine/tags"
  local page
  local versions

  while [ "$next_page" != 'null' ]; do
    page=$(curl -sS "$next_page")
    versions+=$(echo "$page" | jq -r '.results[] | .name')$'\n'
    next_page=$(echo "$page" | jq -r '.next')
  done

  echo "$versions" | grep -E "$SUPPORTED_VERSIONS_REGEXP" | sort -Vr
}

rebuild_since=$(date -d "-$REBUILD_PERIOD" -Is)
last_commit_date_local=$(git log -1 --date=iso-strict --format=%cd)
last_commit_date_utc=$(date -d "$last_commit_date_local" | date -Is)
builds=0
for tag in $(get_supported_versions); do
  if [ $builds -ge $MAX_BUILDS_PER_RUN ]; then
    break
  fi
  official_image_updated_on=$(curl -sS https://hub.docker.com/v2/repositories/library/redmine/tags/$tag | jq -r '.last_updated')
  if curl -f https://hub.docker.com/v2/repositories/$REDMINE_GFM_IMAGE/tags/$tag &> /dev/null; then
    docker pull $REDMINE_GFM_IMAGE:$tag
    gfm_image_build_date=$(docker inspect $REDMINE_GFM_IMAGE:$tag | jq -r '.[] | .Config | .Labels | .["build-date"] // empty')
  fi
  if [[ -z "$gfm_image_build_date" || "$gfm_image_build_date" < $(max "$official_image_updated_on" "$rebuild_since" "$last_commit_date_utc") ]]; then
    echo "building $REDMINE_GFM_IMAGE:$tag..."
    docker build -t $REDMINE_GFM_IMAGE:$tag --build-arg REDMINE_IMAGE=redmine:$tag --build-arg BUILD_DATE="$(date -Is)" .
    docker push $REDMINE_GFM_IMAGE:$tag
    builds=$((builds + 1))
  fi
done
