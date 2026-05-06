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

## Build with SDK (local)

Uses local source code (`USE_SOURCE_VMWARE=true`) — no `.deb` package required.

```bash
docker build \
  --build-arg WITH_SDK=true \
  --build-arg USE_SOURCE_VMWARE=true \
  --file .github/docker/connector/Dockerfile.connector-vmware \
  --tag connector-vmware:local \
  .
```

## Build without SDK (default — used by CI)

The image still works for plain-text credentials in `centreon_vmware.json`.
`encrypted::` credentials require the SDK.

```bash
docker build \
  --file .github/docker/connector/Dockerfile.connector-vmware \
  --tag connector-vmware:local \
  .
```
