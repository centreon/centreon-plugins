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

## CI workflows

Two workflows handle Docker image validation:

| Workflow | Trigger | `PACKAGE_SOURCE` | Description |
|---|---|---|---|
| `connector-vmware.yml` | Source / packaging changes | `mount` | Builds real `.deb`, stages it, builds Docker image |
| `docker-builder-connector-vmware.yml` | Dockerfile / entrypoint changes only | `local` | Validates Dockerfile structure without packages |

## PACKAGE_SOURCE build modes

| `PACKAGE_SOURCE` | Source | Use case |
|---|---|---|
| `local` | `connectors/vmware/src/` | Dockerfile-only CI validation |
| `mount` | `packages-centreon/` bind mount | CI (from cache) or local build with `.deb` |
| `repo` | `packages.centreon.com` apt repo | Ad-hoc build — downloads from stable repo |

`local` and `mount` copy files directly (no `.deb` download), so there's no packaged
version for the image to pick up. Pass `--build-arg VERSION=$(cat .version.plugins)` if
you want the built image labeled with the repo's current plugins-wide version anyway.

## Local build with SDK — from Centreon stable repo

Downloads the stable `.deb` from the Centreon apt repository.
`encrypted::` credentials require the SDK.

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

The image works for plain-text credentials in `centreon_vmware.json`.
`encrypted::` credentials require the SDK.

```bash
docker build \
  --build-arg PACKAGE_SOURCE=repo \
  --file .github/docker/connector/Dockerfile.connector-vmware \
  --tag connector-vmware:local \
  .
```
