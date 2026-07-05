FROM ghcr.io/restic/restic:0.19.1

# hadolint ignore=DL3018
RUN set -eux \
 && apk add --no-cache curl rclone mariadb-backup \
 && curl --version \
 && rclone version
