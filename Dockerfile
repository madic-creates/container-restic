FROM ghcr.io/restic/restic:0.18.1

# hadolint ignore=DL3018
RUN set -eux \
 && apk add --no-cache curl rclone \
 && curl --version \
 && rclone version
