ARG REDMINE_IMAGE=redmine:latest
FROM ${REDMINE_IMAGE}

# Re-declare ARG after its reset - https://github.com/moby/moby/issues/34129
ARG REDMINE_IMAGE=redmine:latest

# do not exec CMD should the script be sourced from a custom entrypoint
RUN sed -iE 's/^\(\s*\)\(exec\s.*\)/\1if [ "$0" = "$BASH_SOURCE" ]; then \2; fi/' /docker-entrypoint.sh

COPY patch /tmp/patch
COPY extract-install-script.awk /

RUN set -eux; \
    image_suffix=$(echo "$REDMINE_IMAGE" | cut -d: -f2 | cut -d- -f2); \
    image_type=$([ "$image_suffix" = "alpine" ] && echo alpine || echo debian); \
    \
    template=Dockerfile-$image_type.template; \
    wget -qO- https://raw.githubusercontent.com/docker-library/redmine/master/$template | \
    /extract-install-script.awk > /install-dependencies.sh; \
    sed -i 's%rm \(/usr/local/bundle/gems/rbpdf-font.*\); \\$%if \[ -f \1 \]; then rm \1; fi%' /install-dependencies.sh; \
    chmod +x /install-dependencies.sh; \
    \
    if [ ! -f lib/redmine/wiki_formatting/common_mark/formatter.rb ]; then \
       if [ "$image_type" = "alpine" ]; then \
         apk add patch; \
       else \
         apt-get update && apt-get install -y patch; \
       fi; \
       cat /tmp/patch/*.patch | patch -p1; \
       /install-dependencies.sh; \
    fi
