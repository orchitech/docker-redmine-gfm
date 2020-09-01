set -eu -o pipefail

export TZ=UTC
DOCKER_HUB_REGISTRY_URL=https://registry-1.docker.io
GFM_IMAGE_NAME=orchitech/redmine-gfm

fail()
{
  echo "$1" >&2
  exit 1
}

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

get_docker_hub_token()
{
  local image=$1
  curl -sS --user "$DOCKER_HUB_USERNAME:$DOCKER_HUB_PASSWORD" \
      "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$image:pull" | jq -r '.token'
}
