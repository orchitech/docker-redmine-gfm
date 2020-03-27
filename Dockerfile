ARG REDMINE_IMAGE=redmine:4.1.0
FROM ${REDMINE_IMAGE}

RUN apt-get update && apt-get install -y \
  gcc \
  make \
  patch

RUN gem install commonmarker -v 0.21.0

COPY patch /tmp/patch
RUN cd /tmp/patch; find . -name '*.patch' -exec bash -c \
    'cd "/usr/src/redmine/$(dirname "$0")" && patch -p1 -i "/tmp/patch/$0"' {} \;
