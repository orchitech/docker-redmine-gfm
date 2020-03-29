ARG REDMINE_IMAGE=redmine:latest
FROM ${REDMINE_IMAGE}

# do not exec CMD should the script be sourced from a custom entrypoint
RUN sed -iE 's/^\(\s*\)\(exec\s.*\)/\1if [ "$0" = "$BASH_SOURCE" ]; then \2; fi/' /docker-entrypoint.sh

COPY patch /tmp/patch

COPY install.sh /
RUN /install.sh
