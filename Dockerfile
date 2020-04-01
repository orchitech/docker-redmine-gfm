ARG REDMINE_IMAGE=redmine:latest
FROM ${REDMINE_IMAGE}

# Re-declare ARG after its reset - https://github.com/moby/moby/issues/34129
ARG REDMINE_IMAGE=redmine:latest

# do not exec CMD should the script be sourced from a custom entrypoint
RUN sed -iE 's/^\(\s*\)\(exec\s.*\)/\1if [ "$0" = "$BASH_SOURCE" ]; then \2; fi/' /docker-entrypoint.sh

COPY patch /tmp/patch
COPY extract-install-script.awk /

RUN image_suffix=$(echo $REDMINE_IMAGE | cut -d: -f2 | cut -d- -f2); \
    image_type=$(case $image_suffix in alpine|passenger) echo $image_suffix;; *) echo debian;; esac); \
    template=Dockerfile-$image_type.template; \
    wget -qO- https://raw.githubusercontent.com/docker-library/redmine/master/$template | \
    /extract-install-script.awk | grep -v '^[[:space:]]*#' | > /install-dependencies.sh; \
    sed -i 's%rm \(/usr/local/bundle/gems/rbpdf-font.*\); \\$%if \[ -f \1 \]; then rm \1; fi%' /install-dependencies.sh; \
    chmod +x /install-dependencies.sh

RUN if [ ! -f lib/redmine/wiki_formatting/common_mark/formatter.rb ]; then /install-dependencies.sh; fi
