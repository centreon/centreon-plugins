"""Shared constants and helpers for the perl-cpan-libraries CI scripts.

Used by:
  check-official-repos.py  –  queries local package manager per distrib
  generate-matrices.py     –  merges partial JSONs into final CI matrices
"""

import json
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request


# ── Matrix defaults ────────────────────────────────────────────────────────────

RPM_DEFAULT_BUILD_DISTRIBS = "el8,el9,el10"
DEB_DEFAULT_BUILD_NAMES    = "bullseye-amd64,bookworm,trixie,jammy,noble"

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
    {"distrib": "el8",  "package_extension": "rpm", "image": "packaging-plugins-alma8"},
    {"distrib": "el9",  "package_extension": "rpm", "image": "packaging-plugins-alma9"},
    {"distrib": "el10", "package_extension": "rpm", "image": "packaging-plugins-alma10"},
]

DEB_BUILD_NAME_INCLUDES = [
    {"build_name": "bullseye-amd64", "distrib": "bullseye", "package_extension": "deb", "image": "packaging-plugins-bullseye"},
    {"build_name": "bookworm",       "distrib": "bookworm", "package_extension": "deb", "image": "packaging-plugins-bookworm"},
    {"build_name": "trixie",         "distrib": "trixie",   "package_extension": "deb", "image": "packaging-plugins-trixie"},
    {"build_name": "jammy",          "distrib": "jammy",    "package_extension": "deb", "image": "packaging-plugins-jammy"},
    {"build_name": "noble",          "distrib": "noble",    "package_extension": "deb", "image": "packaging-plugins-noble"},
    {
        "build_name": "bullseye-arm64",
        "distrib":    "bullseye",
        "package_extension": "deb",
        "image": "packaging-plugins-bullseye-arm64",
        "arch": "arm64",
        "runner_name": "ubuntu-24.04-arm",
    },
]

# ── Derived constants (single source of truth: the include lists above) ────────

RPM_DISTRIBS = [e["distrib"] for e in RPM_DISTRIB_INCLUDES]

# image → check_distrib  (bullseye-arm64 → "bullseye": same official repos, different arch)
DEB_IMAGE_TO_CHECK_DISTRIB = {e["image"]: e["distrib"] for e in DEB_BUILD_NAME_INCLUDES}

# check_distrib → build_names it covers  (e.g. "bullseye" → ["bullseye-amd64", "bullseye-arm64"])
DEB_CHECK_DISTRIB_TO_BUILD_NAMES: dict = {}
for _e in DEB_BUILD_NAME_INCLUDES:
    DEB_CHECK_DISTRIB_TO_BUILD_NAMES.setdefault(_e["distrib"], []).append(_e["build_name"])

# ── Centreon stable repository ─────────────────────────────────────────────────

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
    """
    name = (dist_name or fallback_module_name.replace("::", "-")).lower()
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
# CENTREON STABLE REPOSITORY HELPERS
# ══════════════════════════════════════════════════════════════════════════════

_RPM_PKG_RE = re.compile(r"^perl-(.+?)-([0-9v][0-9.]*)-\d+\.\w+\.(noarch|x86_64)\.rpm$")
_DEB_PKG_RE = re.compile(r"^(.+?)_([0-9v][0-9.]*)[+\-].+_[^_]+\.deb$")

_deb_pool_cache: dict = {}


_ALLOWED_ARTIFACTORY_HOSTS = {"packages.centreon.com"}


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


def get_stable_rpm_packages(base_url, distrib):
    """Return {cpan_dist_name: version} for packages already in the Centreon stable RPM repo.

    Example filename: perl-JSON-Path-1.0.6-2.el9.noarch.rpm
      → cpan_dist_name = "JSON-Path", version = "1.0.6"
    """
    files = _artifactory_list_folder(
        base_url, f"rpm-plugins/{distrib}/stable/noarch/RPMS/{CPAN_MODULE_NAME}"
    )
    result = {}
    for fname in files:
        m = _RPM_PKG_RE.match(fname)
        if m:
            result[m.group(1)] = m.group(2)
    return result


def get_stable_deb_packages(base_url, distrib, arch="amd64", family="debian", suffix=""):
    """Return {pkg_name: version} for packages already in the Centreon stable DEB repo.

    All distribs of the same family (debian / ubuntu) share the same pool folder;
    files are distinguished by the distrib suffix in their version string and the
    arch in their filename.

    Example filename: libjson-path-perl_1.0.6+deb12u1_amd64.deb
      → pkg_name = "libjson-path-perl", version = "1.0.6"

    family and suffix come from the parse-distrib action outputs, passed through
    the partial-matrix JSON produced by check-official-repos.py.
    """
    repo = "ubuntu-plugins-stable" if family == "ubuntu" else "apt-plugins-stable"
    if repo not in _deb_pool_cache:
        _deb_pool_cache[repo] = _artifactory_list_folder(
            base_url, f"{repo}/pool/{CPAN_MODULE_NAME}"
        )
    result = {}
    for fname in _deb_pool_cache[repo]:
        if not fname.endswith(f"_{arch}.deb"):
            continue
        if suffix and suffix not in fname:
            continue
        m = _DEB_PKG_RE.match(fname)
        if m:
            result[m.group(1)] = m.group(2)
    return result
