ARG REDMINE_IMAGE=redmine:4.1.0
FROM ${REDMINE_IMAGE}

# exec cmd only when the entrypoint is not run from other script to allow running the default
# entrypoint in custom entrypoint script
RUN sed -iE 's/^\(\s*\)\(exec\s.*\)/\1if [ "$0" = "$BASH_SOURCE" ]; then \2; fi/' /docker-entrypoint.sh

COPY patch /tmp/patch

RUN apt-get update && apt-get install -y gcc make patch && \
    \
    cat /tmp/patch/*.patch | patch -p1 && \
    \
    gosu redmine bundle install --jobs "$(nproc)" --without development test && \
    for adapter in mysql2 postgresql sqlserver sqlite3; do \
      echo "$RAILS_ENV:" > ./config/database.yml; \
      echo "  adapter: $adapter" >> ./config/database.yml; \
      gosu redmine bundle install --jobs "$(nproc)" --without development test; \
      cp Gemfile.lock "Gemfile.lock.${adapter}"; \
    done && \
    rm ./config/database.yml; \
    # fix permissions for running as an arbitrary user
    chmod -R ugo=rwX Gemfile.lock "$GEM_HOME"; \
    rm -rf ~redmine/.bundle; \
    \
    apt-get remove -y gcc make patch && \
    rm -rf /var/lib/apt/lists/* \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    find /usr/local -type f -executable -exec ldd '{}' ';' \
        | awk '/=>/ { print $(NF-1) }' \
        | sort -u \
        | grep -v '^/usr/local/' \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual \
        ; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
