# sdks-vmware

This directory is used to provide the proprietary VMware Perl SDK files when building
the `connector-vmware` Docker image with full functionality.

The SDK files are **not included** in this repository due to Broadcom licensing restrictions.

## Required files

| File | Description |
|------|-------------|
| `VMware-vSphere-Perl-SDK-7.0.0-17698549.x86_64.tar.gz` | VMware vSphere Perl SDK 7.0 |
| `vsan-sdk-perl.zip` | VMware vSAN Management SDK for Perl |

## How to get the files

1. Create a free account at [Broadcom Developer Portal](https://developer.broadcom.com)
2. Download **VMware vSphere Perl SDK 7.0** and **vSAN SDK for Perl**
3. Place the downloaded archives in this directory

## CI workflow

`connector-vmware.yml` builds the real `.deb`, stages it into `packages-centreon/`, and
builds the Docker image with `PACKAGE_SOURCE=mount` and `WITH_SDK=false` — both passed
explicitly as build-args, so it doesn't depend on this Dockerfile's own `ARG` defaults.
It never publishes the image (`push: false`); its only job is proving the Dockerfile
builds. It's triggered by changes under `connectors/vmware/`, this Dockerfile, or the
entrypoint scripts.

## PACKAGE_SOURCE build modes

| `PACKAGE_SOURCE` | Source | Use case |
|---|---|---|
| `repo` (default) | `packages.centreon.com` apt repo | Local/dev build — downloads from the stable repo |
| `mount` | `packages-centreon/` bind mount | CI (from cache) or local build with a `.deb` you already have |
| `local` | `connectors/vmware/src/` | Dockerfile-only structure validation, no real package |

`WITH_SDK` also defaults to `true`: this image is primarily meant for local/dev use,
where the SDK is required for the daemon to do anything at all (see below) — CI passes
`WITH_SDK=false` explicitly to validate the Dockerfile without the licensed SDK.

`local` and `mount` copy files directly (no `.deb` download), so there's no packaged
version for the image to pick up. Pass `--build-arg VERSION=$(cat .version.plugins)` if
you want the built image labeled with the repo's current plugins-wide version anyway.

## Local build with SDK — from Centreon stable repo

This is now the default — both flags below match the Dockerfile's own defaults, so a
plain `docker build -f .github/docker/connector/Dockerfile.connector-vmware .` from the
repo root does the same thing. Kept explicit here for clarity:

```bash
docker build \
  --build-arg PACKAGE_SOURCE=repo \
  --build-arg WITH_SDK=true \
  --file .github/docker/connector/Dockerfile.connector-vmware \
  --tag connector-vmware:local \
  .
```

By default this downloads whatever is currently latest in the `${STABILITY}` channel
(`STABILITY` defaults to `stable`). Pass `--build-arg VERSION=20260300-1+deb13u1` to pin
an exact release instead — the build fails clearly if that version isn't published in
the selected channel. Either way, `org.opencontainers.image.version` on the built image
reflects whatever `VERSION` you passed (empty if you didn't pin one).

## Local build with SDK — from local .deb packages

Place the `.deb` package in a `packages-centreon/` directory at the repo root, then:

```bash
docker build \
  --build-arg PACKAGE_SOURCE=mount \
  --build-arg WITH_SDK=true \
  --file .github/docker/connector/Dockerfile.connector-vmware \
  --tag connector-vmware:local \
  .
```

## Local build without SDK

Mainly useful to validate the Dockerfile/repo-download path builds without the licensed
SDK on hand — matches what CI does. The resulting image **cannot actually run the
daemon**: `centreon::script::centreon_vmware` unconditionally requires
`VMware::VIRuntime`/`VMware::VILib` (for both plain-text and `encrypted::` credentials),
so without the SDK it logs a clear "you will need the Perl VMware SDK" error and exits
immediately.

```bash
docker build \
  --build-arg PACKAGE_SOURCE=repo \
  --build-arg WITH_SDK=false \
  --file .github/docker/connector/Dockerfile.connector-vmware \
  --tag connector-vmware:local \
  .
```
