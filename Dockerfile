ARG FROM_IMAGE_DIGEST
FROM redmine@${FROM_IMAGE_DIGEST}

# Re-declare ARG after its reset - https://github.com/moby/moby/issues/34129
ARG FROM_IMAGE_DIGEST

ARG LINUX_DISTRIBUTION
ARG REDMINE_GFM_VERSION

LABEL from-image-digest="$FROM_IMAGE_DIGEST"
LABEL redmine-gfm-version="$REDMINE_GFM_VERSION"

# do not exec CMD should the script be sourced from a custom entrypoint
RUN sed -i -E 's/^(\s*)(exec\s.*)/\1if [ "$0" = "$BASH_SOURCE" ]; then \2; fi/' /docker-entrypoint.sh

COPY patches /tmp/patches
COPY scripts /scripts

RUN set -eux; \
    template=Dockerfile-$LINUX_DISTRIBUTION.template; \
    wget -qO- https://raw.githubusercontent.com/docker-library/redmine/master/$template | \
    /scripts/extract-install-script.awk > /scripts/install-dependencies.sh; \
    sed -i 's%rm \(/usr/local/bundle/gems/rbpdf-font.*\); \\$%if \[ -f \1 \]; then rm \1; fi%' /scripts/install-dependencies.sh; \
    chmod +x /scripts/install-dependencies.sh; \
    \
    if [ ! -f lib/redmine/wiki_formatting/common_mark/formatter.rb ]; then \
       if [ "$LINUX_DISTRIBUTION" = "alpine" ]; then \
         apk add patch; \
       else \
         apt-get update && apt-get install -y patch; \
       fi; \
       /scripts/apply-patches.sh "$PWD" /tmp/patches "$REDMINE_VERSION"; \
       /scripts/install-dependencies.sh; \
    fi; \
    rm -r /tmp/patches
