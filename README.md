# container-restic

Custom container image based on [restic](https://restic.net/), extended with `curl`, `rclone`, and `mariadb-backup`. Used as the primary backup container in the GitOps repo [madic-creates/k3s-git-ops](https://github.com/madic-creates/k3s-git-ops).

## Purpose

The official `ghcr.io/restic/restic` image ships only the restic binary. The Kubernetes CronJobs in the k3s cluster also need:

- **`rclone`** – as a restic backend (e.g. for S3-compatible storage, WebDAV, SFTP, cloud providers) and for standalone sync tasks.
- **`curl`** – for healthchecks (e.g. [healthchecks.io](https://healthchecks.io/)) and simple HTTP requests in pre-/post-hooks of backup jobs.
- **`mariadb-backup`** – for consistent hot backups of MariaDB/MySQL databases (physical backup via `mariabackup`), piped directly into restic.

Instead of installing these tools on every pod start, they are baked into the image.

## Image

The image is published at:

```
ghcr.io/madic-creates/container-restic:latest
```

### Tags

| Tag      | Description                                  |
| -------- | -------------------------------------------- |
| `latest` | Latest build from the `main` branch          |
| `<sha>`  | Short commit SHA (immutable, use for pinning) |

Production workloads should pin to a specific SHA tag.

## Base

| Component       | Source                                    |
| --------------- | ----------------------------------------- |
| restic          | `ghcr.io/restic/restic:0.18.1` (Alpine)   |
| rclone          | Alpine package (`apk add rclone`)         |
| curl            | Alpine package (`apk add curl`)           |
| mariadb-backup  | Alpine package (`apk add mariadb-backup`) |

Updates to the base version and Alpine packages are handled by [Renovate](https://docs.renovatebot.com/) (see `renovate.json`). Patch and minor updates are auto-merged, major updates manually.

## Build locally

```bash
docker build -t container-restic:latest .
docker run --rm container-restic:latest restic version
docker run --rm container-restic:latest rclone version
docker run --rm container-restic:latest mariabackup --version
```

## CI/CD

The build runs via GitHub Actions (`.github/workflows/build.yaml`) and is triggered by:

- Pushes to `main` that touch `Dockerfile` or the workflow file
- Manual runs (`workflow_dispatch`)

The image is built with the GitHub Actions cache and pushed to the GitHub Container Registry (GHCR).

## Usage in k3s-git-ops

In the cluster, this image is consumed by backup CronJobs (e.g. volume snapshots, database dumps). A typical job flow:

1. `curl` pings the healthcheck start endpoint
2. `restic backup` sends data to the configured backend (often via an `rclone` remote)
3. `restic forget --prune` applies the retention policy
4. `curl` pings the healthcheck success (or failure) endpoint

Concrete job definitions live in the [k3s-git-ops](https://github.com/madic-creates/k3s-git-ops) repo.
