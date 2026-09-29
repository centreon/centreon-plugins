"""Shared constants and helpers for the perl-cpan-libraries CI scripts.

Used by:
  check-official-repos.py  –  queries local package manager per distrib
  generate-matrices.py     –  merges partial JSONs into final CI matrices
"""

import gzip
import json
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET


# ── Matrix defaults ────────────────────────────────────────────────────────────

RPM_DEFAULT_BUILD_DISTRIBS = "el8,el9,el10"
DEB_DEFAULT_BUILD_NAMES    = "bookworm,trixie,jammy,noble"

RPM_DEFAULTS = {
    "rpm_dependencies": "",
    "rpm_provides": "",
    "version": "",
    "spec_file": "",
    "no-auto-depends": "false",
    "preinstall_cpanlibs": "",
    "preinstall_packages": "",
    "revision": "2",
}

DEB_DEFAULTS = {
    "runner_name": "ubuntu-24.04",
    "arch": "amd64",
    "deb_dependencies": "",
    "deb_provides": "",
    "version": "",
    "use_dh_make_perl": "true",
    "no-auto-depends": "false",
    "preinstall_cpanlibs": "",
    "preinstall_packages": "",
    "revision": "1",
}

# ── Fixed include entries ──────────────────────────────────────────────────────

RPM_DISTRIB_INCLUDES = [
    {"distrib": "el8",  "package_extension": "rpm", "image": "packaging:alma8"},
    {"distrib": "el9",  "package_extension": "rpm", "image": "packaging:alma9"},
    {"distrib": "el10", "package_extension": "rpm", "image": "packaging:alma10"},
]

DEB_BUILD_NAME_INCLUDES = [
    {"build_name": "bookworm",       "distrib": "bookworm", "package_extension": "deb", "image": "packaging:bookworm"},
    {"build_name": "trixie",         "distrib": "trixie",   "package_extension": "deb", "image": "packaging:trixie"},
    {"build_name": "jammy",          "distrib": "jammy",    "package_extension": "deb", "image": "packaging:jammy"},
    {"build_name": "noble",          "distrib": "noble",    "package_extension": "deb", "image": "packaging:noble"},
    {
        "build_name": "bookworm-arm64",
        "distrib":    "bookworm",
        "package_extension": "deb",
        "image": "packaging:bookworm",
        "arch": "arm64",
        "runner_name": "ubuntu-24.04-arm",
    },
    {
        "build_name": "trixie-arm64",
        "distrib":    "trixie",
        "package_extension": "deb",
        "image": "packaging:trixie",
        "arch": "arm64",
        "runner_name": "ubuntu-24.04-arm",
    },
]

# ── Derived constants (single source of truth: the include lists above) ────────

RPM_DISTRIBS = [e["distrib"] for e in RPM_DISTRIB_INCLUDES]

# image → check_distrib  (same official repos can cover several arches/build names)
DEB_IMAGE_TO_CHECK_DISTRIB = {e["image"]: e["distrib"] for e in DEB_BUILD_NAME_INCLUDES}

# check_distrib → build_names it covers  (e.g. "bookworm" → ["bookworm"])
DEB_CHECK_DISTRIB_TO_BUILD_NAMES: dict = {}
for _e in DEB_BUILD_NAME_INCLUDES:
    DEB_CHECK_DISTRIB_TO_BUILD_NAMES.setdefault(_e["distrib"], []).append(_e["build_name"])

# ── Centreon repository ────────────────────────────────────────────────────────

CPAN_MODULE_NAME = "perl-cpan-libraries"


# ══════════════════════════════════════════════════════════════════════════════
# GENERIC HELPERS
# ══════════════════════════════════════════════════════════════════════════════

def csv_split(s):
    """Split a comma-separated string into a stripped, non-empty list."""
    return [v.strip() for v in s.split(",") if v.strip()]


def _run_bash(script):
    """Run a bash snippet and return stdout."""
    return subprocess.run(
        ["bash", "-c", script], stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).stdout.decode("utf-8", errors="replace")


def _parse_found_lines(stdout):
    """Parse 'FOUND:<lib>:<version>' lines produced by bash snippets."""
    found = {}
    for line in stdout.splitlines():
        if line.startswith("FOUND:"):
            parts = line.split(":", 2)
            if len(parts) == 3:
                found[parts[1]] = parts[2]
    return found


def versions_match(found_version, required_version):
    """True when *found_version* satisfies *required_version*.

    Handles 'v' prefix and Debian revision suffix (e.g. '0.04-1' → '0.04').
    """
    if not required_version:
        return True
    found_clean = found_version.split("-")[0] if found_version else ""
    return (
        found_clean == required_version
        or f"v{found_clean}" == required_version
        or found_version == required_version
        or f"v{found_version}" == required_version
    )


def extras_from_partials(partials):
    """Build {distrib: {name: {cpan_version, cpan_dist_name}}} from loaded partial JSONs."""
    return {
        distrib: {
            item["name"]: {
                "cpan_version":   item.get("cpan_version",   ""),
                "cpan_dist_name": item.get("cpan_dist_name", ""),
            }
            for item in data.get("lib_includes", [])
        }
        for distrib, data in partials.items()
    }


# ══════════════════════════════════════════════════════════════════════════════
# CPAN / PACKAGE MANAGER HELPERS
# ══════════════════════════════════════════════════════════════════════════════

def dist_to_deb_package(dist_name, fallback_module_name=""):
    """Convert CPAN distribution name to deb package name.

    "Jmx4Perl"      → "libjmx4perl-perl"
    "Net-Curl"       → "libnet-curl-perl"
    "Libssh-Session" → "libssh-session-perl"

    Falls back to deriving from fallback_module_name (CPAN module name) when dist_name is empty.
    "ARGV::Struct" → "libargv-struct-perl",  "Libssh::Session" → "libssh-session-perl"
    "Crypt-Blowfish_PP" → "libcrypt-blowfish-pp-perl"  (no '_' allowed in deb package names)
    """
    name = (dist_name or fallback_module_name.replace("::", "-")).lower().replace("_", "-")
    if not name:
        return ""
    return f"{name}-perl" if name.startswith("lib") else f"lib{name}-perl"


def get_cpanm_infos(lib_names):
    """Return {lib_name: (dist_name, version)} via batched cpanm --info calls.

    dist_name is the raw CPAN distribution name (e.g. "Jmx4Perl", "Net-Curl").
    Example: JMX::Jmx4Perl → ("Jmx4Perl", "1.13")

    Falls back to ("", "") when cpanm returns nothing.
    Uses '|' as separator to safely handle '::' in lib names.
    """
    if not lib_names:
        return {}
    checks = []
    for lib in lib_names:
        checks.append(
            f'tarball=$(cpanm --info "{lib}" 2>/dev/null | sed "s|.*/||"); '
            f'if [ -n "$tarball" ]; then '
            f'  dist=$(echo "$tarball" | sed "s/-[0-9v][0-9.]*\\.tar\\.gz$//"); '
            f'  version=$(echo "$tarball" | grep -oP "(?<=-)[0-9v][0-9.]*(?=\\.tar\\.gz$)"); '
            f'else '
            f'  dist=""; version=""; '
            f'fi; '
            f'echo "CPANINFO|{lib}|$dist|$version"'
        )
    result = {}
    for line in _run_bash("; ".join(checks)).splitlines():
        if line.startswith("CPANINFO|"):
            parts = line.split("|")
            if len(parts) == 4:
                result[parts[1]] = (parts[2], parts[3])
    return result


def check_rpm(lib_names):
    """Return {lib_name: version} for libs present in the official RPM repos."""
    if not lib_names:
        return {}
    checks = []
    for lib in lib_names:
        checks.append(
            f'result=$(dnf -q provides "perl({lib})" 2>&1); '
            f'if echo "$result" | grep -qiv "no matches\\|Error:"; then '
            f'  ver=$(echo "$result" | grep -oP "= \\K[v0-9][0-9.]*" | head -1); '
            f'  echo "FOUND:{lib}:${{ver:-unknown}}"; '
            f'fi'
        )
    return _parse_found_lines(_run_bash("; ".join(checks)))


def check_deb(lib_to_pkg):
    """Return {lib_name: repo_version} for libs present in the official DEB repos.

    lib_to_pkg: dict mapping CPAN lib name to the deb package name to look up.
    """
    if not lib_to_pkg:
        return {}
    subprocess.run(["apt-get", "update", "-qq"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    checks = []
    for lib, pkg in lib_to_pkg.items():
        pkg_clean = pkg.replace("_", "")
        checks.append(
            f'c=$(apt-cache policy "{pkg}" 2>/dev/null | grep "Candidate:" | awk \'{{print $2}}\'); '
            f'[ -z "$c" ] || [ "$c" = "(none)" ] && '
            f'c=$(apt-cache policy "{pkg_clean}" 2>/dev/null | grep "Candidate:" | awk \'{{print $2}}\'); '
            f'[ -n "$c" ] && [ "$c" != "(none)" ] && echo "FOUND:{lib}:$c"'
        )
    return _parse_found_lines(_run_bash("; ".join(checks)))


def detect_package_manager():
    """Return 'rpm', 'deb', or None depending on what's available."""
    if shutil.which("dnf"):
        return "rpm"
    if shutil.which("apt-get"):
        return "deb"
    return None


def filter_to_includes(libs, pkg_key, cpanm_infos, available):
    """Filter libs against available versions, return (names, lib_includes).

    Skips any lib already in *available* at the expected version.
    Each kept entry is enriched with cpan_dist_name and cpan_version.
    """
    names, includes = [], []
    for lib in libs:
        name               = lib["name"]
        pkg_config         = lib[pkg_key]
        dist_name, version = cpanm_infos.get(name, ("", ""))
        found = available.get(name)
        if found is not None:
            required = pkg_config.get("version", "") or version
            if versions_match(found, required):
                print(f"  Skip {name}: official repo has v{found}", file=sys.stderr)
                continue
        names.append(name)
        includes.append({
            "name": name, **pkg_config,
            "cpan_dist_name": dist_name,
            "cpan_version":   version,
        })
    return names, includes


# ══════════════════════════════════════════════════════════════════════════════
# CENTREON REPOSITORY HELPERS
# ══════════════════════════════════════════════════════════════════════════════

_RPM_PKG_RE = re.compile(r"^perl-(.+?)-([0-9v][0-9.]*)-\d+\.\w+\.(noarch|x86_64)\.rpm$")
_DEB_VERSION_RE = re.compile(r"^([0-9v][0-9.]*)(?:[+\-]|$)")

_deb_packages_cache: dict = {}  # (repo, distrib, arch) → {pkg_name: version}


_ALLOWED_ARTIFACTORY_HOSTS = {"centreon.jfrog.io", "packages.centreon.com"}


def _artifactory_list_folder(base_url, repo_path):
    """Return list of filenames in an Artifactory folder (public API, no auth).

    Uses the Artifactory storage API:  GET {base_url}/artifactory/api/storage/{repo_path}
    Returns an empty list on any error (network, 404, unexpected format, etc.).
    """
    # Validate base_url before constructing the full URL (SSRF prevention).
    parsed_base = urllib.parse.urlparse(base_url)
    if parsed_base.scheme != "https" or parsed_base.hostname not in _ALLOWED_ARTIFACTORY_HOSTS:
        print(f"  WARNING: {base_url} is not an allowed Artifactory base URL, skipping.", file=sys.stderr)
        return []
    url = f"{base_url}/artifactory/api/storage/{repo_path}"
    # Re-validate the full URL after concatenation to catch any injection via repo_path.
    parsed_url = urllib.parse.urlparse(url)
    if parsed_url.scheme != "https" or parsed_url.hostname not in _ALLOWED_ARTIFACTORY_HOSTS:
        print(f"  WARNING: {url} is not an allowed Artifactory URL, skipping.", file=sys.stderr)
        return []
    url = f"{base_url}/artifactory/api/storage/{repo_path}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "generate-cpan-matrix/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        return [c["uri"].lstrip("/") for c in data.get("children", []) if not c.get("folder")]
    except Exception as exc:
        print(f"  WARNING: could not list {url}: {exc}", file=sys.stderr)
        return []


def get_centreon_rpm_packages(base_url, distrib, stability):
    """Return {cpan_dist_name: version} for packages already in the Centreon RPM repo.

    Example filename: perl-JSON-Path-1.0.6-2.el9.noarch.rpm
      → cpan_dist_name = "JSON-Path", version = "1.0.6"
    """
    files = _artifactory_list_folder(
        base_url, f"rpm-plugins/{distrib}/{stability}/noarch/RPMS/{CPAN_MODULE_NAME}"
    )
    result = {}
    for fname in files:
        m = _RPM_PKG_RE.match(fname)
        if m:
            result[m.group(1)] = m.group(2)
    return result


def _fetch_packages_index(base_url, repo, distrib, arch):
    """Fetch and parse the Packages index for a specific DEB distrib/arch.

    Uses the direct download URL:
      GET {base_url}/artifactory/{repo}/dists/{distrib}/main/binary-{arch}/Packages
    Returns an empty dict on any error.
    """
    parsed_base = urllib.parse.urlparse(base_url)
    if parsed_base.scheme != "https" or parsed_base.hostname not in _ALLOWED_ARTIFACTORY_HOSTS:
        print(f"  WARNING: {base_url} is not an allowed Artifactory base URL, skipping.", file=sys.stderr)
        return {}
    url = f"{base_url}/artifactory/{repo}/dists/{distrib}/main/binary-{arch}/Packages"
    parsed_url = urllib.parse.urlparse(url)
    if parsed_url.scheme != "https" or parsed_url.hostname not in _ALLOWED_ARTIFACTORY_HOSTS:
        print(f"  WARNING: {url} is not an allowed Artifactory URL, skipping.", file=sys.stderr)
        return {}
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "generate-cpan-matrix/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            content = resp.read().decode("utf-8")
    except Exception as exc:
        print(f"  WARNING: could not fetch {url}: {exc}", file=sys.stderr)
        return {}
    result = {}
    for stanza in content.split("\n\n"):
        pkg_name = None
        version = None
        for line in stanza.splitlines():
            if line.startswith("Package: "):
                pkg_name = line[9:].strip()
            elif line.startswith("Version: "):
                m = _DEB_VERSION_RE.match(line[9:].strip())
                if m:
                    version = m.group(1)
        if pkg_name and version:
            result[pkg_name] = version
    return result


def get_centreon_deb_packages(base_url, distrib, stability, arch="amd64", family="debian"):
    """Return {pkg_name: version} for packages already in the Centreon DEB repo.

    Queries and merges the Packages indexes for the given arch and for 'all':
      dists/{distrib}/main/binary-{arch}/Packages
      dists/{distrib}/main/binary-all/Packages

    Example entry: Package: libjson-path-perl, Version: 1.0.6+deb12u1-1
      → pkg_name = "libjson-path-perl", version = "1.0.6"
    """
    repo = f"ubuntu-plugins-{stability}" if family == "ubuntu" else f"apt-plugins-{stability}"
    cache_key = (repo, distrib, arch)
    if cache_key not in _deb_packages_cache:
        packages = _fetch_packages_index(base_url, repo, distrib, arch)
        if arch != "all":
            packages.update(_fetch_packages_index(base_url, repo, distrib, "all"))
        _deb_packages_cache[cache_key] = packages
    return _deb_packages_cache[cache_key]


# ── Published (version, revision) lookups, read from the public repo metadata ──

_RPM_REPO_NS = {"repo": "http://linux.duke.edu/metadata/repo"}
_RPM_COMMON_NS = "{http://linux.duke.edu/metadata/common}"

_published_cache: dict = {}


def _fetch_bytes(base_url, path):
    """GET {base_url}/{path} from an allowed host; return None on any error."""
    url = f"{base_url}/{path}"
    for candidate in (base_url, url):
        parsed = urllib.parse.urlparse(candidate)
        if parsed.scheme != "https" or parsed.hostname not in _ALLOWED_ARTIFACTORY_HOSTS:
            print(f"  WARNING: {candidate} is not an allowed Centreon repository URL, skipping.", file=sys.stderr)
            return None
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "generate-cpan-matrix/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.read()
    except Exception as exc:
        print(f"  WARNING: could not fetch {url}: {exc}", file=sys.stderr)
        return None


def get_centreon_rpm_published(base_url, distrib, stability):
    """Return {cpan_dist_name: {(version, revision), …}} from the RPM repo metadata.

    Every published build is kept (noarch and x86_64), e.g. perl-JSON-Path 1.0.6-2.el9
      → "JSON-Path": {("1.0.6", "2")}
    """
    cache_key = ("rpm", base_url, distrib, stability)
    if cache_key in _published_cache:
        return _published_cache[cache_key]
    result: dict = {}
    for arch in ("noarch", "x86_64"):
        repo_path = f"rpm-plugins/{distrib}/{stability}/{arch}"
        repomd = _fetch_bytes(base_url, f"{repo_path}/repodata/repomd.xml")
        if repomd is None:
            continue
        location = ET.fromstring(repomd).find("repo:data[@type='primary']/repo:location", _RPM_REPO_NS)
        if location is None:
            continue
        primary = _fetch_bytes(base_url, f"{repo_path}/{location.get('href')}")
        if primary is None:
            continue
        for pkg in ET.fromstring(gzip.decompress(primary)).iter(f"{_RPM_COMMON_NS}package"):
            name = pkg.findtext(f"{_RPM_COMMON_NS}name", "")
            version = pkg.find(f"{_RPM_COMMON_NS}version")
            if not name.startswith("perl-") or version is None:
                continue
            revision = version.get("rel", "").split(".")[0]
            result.setdefault(name[len("perl-"):], set()).add((version.get("ver", ""), revision))
    _published_cache[cache_key] = result
    return result


def get_centreon_deb_published(base_url, distrib, stability, arch="amd64", family="debian"):
    """Return {pkg_name: {(version, revision), …}} from the DEB Packages indexes ({arch} + all).

    Every published build is kept, e.g. libssh-session-perl 1.1-2+deb12u1
      → "libssh-session-perl": {("1.1", "2")}
    """
    repo = f"ubuntu-plugins-{stability}" if family == "ubuntu" else f"apt-plugins-{stability}"
    cache_key = ("deb", base_url, repo, distrib, arch)
    if cache_key in _published_cache:
        return _published_cache[cache_key]
    result: dict = {}
    for index_arch in {arch, "all"}:
        content = _fetch_bytes(base_url, f"artifactory/{repo}/dists/{distrib}/main/binary-{index_arch}/Packages")
        if content is None:
            continue
        for stanza in content.decode("utf-8", errors="replace").split("\n\n"):
            fields = dict(line.split(": ", 1) for line in stanza.splitlines() if ": " in line)
            upstream = _DEB_VERSION_RE.match(re.sub(r"^\d+:", "", fields.get("Version", "").strip()))
            if "Package" not in fields or not upstream:
                continue
            # "1.1-2+deb12u1" / "0.06-1-0ubuntu.24.04" → 2 / 1, legacy "0.06+deb12u1-1" → 1,
            # no revision at all ("0.06") → None, which matches any revision
            rest = upstream.string[upstream.end():]
            lead, trail = re.match(r"\d+", rest), re.search(r"-(\d+)$", rest)
            revision = lead.group(0) if lead else trail.group(1) if trail else None
            result.setdefault(fields["Package"].strip(), set()).add((upstream.group(1), revision))
    _published_cache[cache_key] = result
    return result


def published_matches(published, required_version, required_revision=None):
    """True when one of the published (version, revision) pairs satisfies the requirement.

    A None revision (published or required) is not compared.
    """
    return any(
        versions_match(version, required_version)
        and (revision is None or required_revision is None or revision == required_revision)
        for version, revision in published
    )
