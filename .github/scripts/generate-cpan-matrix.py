#!/usr/bin/env python3
"""Generate filtered GitHub Actions matrices for perl-cpan-libraries workflow.

Two modes
---------
1. Check mode  (runs inside an official distrib container via CI matrix)
   Queries the local package manager, filters out already-packaged libs,
   and writes a partial-matrix JSON file for this distrib.

       python3 generate-cpan-matrix.py \\
           --check-distrib bookworm \\
           --output official-repos/partial-matrix-bookworm.json \\
           .github/packaging/cpan-libraries.json

2. Merge mode  (runs on the ubuntu CI runner after all check jobs)
   Reads the partial-matrix JSON files produced in check mode and merges
   them into matrix_rpm / matrix_deb written to GITHUB_OUTPUT.

       python3 generate-cpan-matrix.py \\
           --partial-matrices-dir official-repos/ \\
           --artifactory-url https://packages.centreon.com \\
           .github/packaging/cpan-libraries.json

   Without --partial-matrices-dir the matrices are generated without
   filtering (useful for local debugging).
   Without --artifactory-url the Centreon stable repo check is skipped.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
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

RPM_DISTRIBS = ["el8", "el9", "el10"]

DEB_IMAGES = [
    "packaging-plugins-bullseye",
    "packaging-plugins-bookworm",
    "packaging-plugins-trixie",
    "packaging-plugins-jammy",
    "packaging-plugins-noble",
    "packaging-plugins-bullseye-arm64",
]

# check_distrib → build_names it covers (same official repos, different arches)
DEB_CHECK_DISTRIB_TO_BUILD_NAMES = {
    "bullseye": ["bullseye-amd64", "bullseye-arm64"],
    "bookworm": ["bookworm"],
    "trixie":   ["trixie"],
    "jammy":    ["jammy"],
    "noble":    ["noble"],
}

# image → check_distrib (for merge step)
DEB_IMAGE_TO_CHECK_DISTRIB = {
    "packaging-plugins-bullseye":       "bullseye",
    "packaging-plugins-bookworm":       "bookworm",
    "packaging-plugins-trixie":         "trixie",
    "packaging-plugins-jammy":          "jammy",
    "packaging-plugins-noble":          "noble",
    "packaging-plugins-bullseye-arm64": "bullseye",
}

# ── Centreon stable repository ─────────────────────────────────────────────────

CPAN_MODULE_NAME   = "perl-cpan-libraries"
UBUNTU_DISTRIBS    = frozenset({"jammy", "noble"})

# Suffix appended to the package version in DEB filenames (from parse-distrib action)
# e.g. libjson-path-perl_1.0.6+deb12u1_amd64.deb  →  distrib suffix = "deb12u1"
DEB_DISTRIB_SUFFIX = {
    "bullseye": "deb11u1",
    "bookworm":  "deb12u1",
    "trixie":    "deb32u1",
    "jammy":     "0ubuntu.22.04",
    "noble":     "0ubuntu.24.04",
}


# ══════════════════════════════════════════════════════════════════════════════
# CHECK MODE – runs inside a distribution container
# ══════════════════════════════════════════════════════════════════════════════

def cpan_to_deb_package(module_name):
    """Fallback: derive deb package name from CPAN module name.

    ARGV::Struct → libargv-struct-perl,  Libssh::Session → libssh-session-perl.
    Used only when cpanm is unavailable; prefer get_cpanm_deb_infos().
    """
    name = module_name.replace("::", "-").lower()
    if name.startswith("lib"):
        return f"{name}-perl"
    return f"lib{name}-perl"


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


def dist_to_deb_package(dist_name, fallback_module_name=""):
    """Convert CPAN distribution name to deb package name.

    "Jmx4Perl"      → "libjmx4perl-perl"
    "Net-Curl"       → "libnet-curl-perl"
    "Libssh-Session" → "libssh-session-perl"

    Falls back to cpan_to_deb_package(fallback_module_name) when dist_name is empty.
    """
    if not dist_name:
        return cpan_to_deb_package(fallback_module_name) if fallback_module_name else ""
    name = dist_name.lower()
    if name.startswith("lib"):
        return f"{name}-perl"
    return f"lib{name}-perl"


def _run_bash(script):
    """Run a bash one-liner and return stdout."""
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


def detect_package_manager():
    if shutil.which("dnf"):
        return "rpm"
    if shutil.which("apt-get"):
        return "deb"
    return None


# ══════════════════════════════════════════════════════════════════════════════
# CENTREON STABLE REPO CHECK – queries the public Artifactory instance
# ══════════════════════════════════════════════════════════════════════════════

def _artifactory_list_folder(base_url, repo_path):
    """Return list of filenames in an Artifactory folder (public API, no auth).

    Uses the Artifactory storage API:  GET {base_url}/artifactory/api/storage/{repo_path}
    Returns an empty list on any error (network, 404, unexpected format, etc.).
    """
    url = f"{base_url}/artifactory/api/storage/{repo_path}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "generate-cpan-matrix/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        return [c["uri"].lstrip("/") for c in data.get("children", []) if not c.get("folder")]
    except Exception as exc:
        print(f"  WARNING: could not list {url}: {exc}", file=sys.stderr)
        return []


_deb_pool_cache: dict = {}


def get_stable_rpm_packages(base_url, distrib):
    """Return {cpan_dist_name: version} for packages already in the Centreon stable RPM repo.

    Example filename: perl-JSON-Path-1.0.6-2.el9.noarch.rpm
      → cpan_dist_name = "JSON-Path", version = "1.0.6"
    """
    path  = f"rpm-plugins/{distrib}/stable/noarch/RPMS/{CPAN_MODULE_NAME}"
    files = _artifactory_list_folder(base_url, path)
    result = {}
    for fname in files:
        m = re.match(
            r"^perl-(.+?)-([0-9v][0-9.]*)-\d+\.\w+\.(noarch|x86_64)\.rpm$", fname
        )
        if m:
            result[m.group(1)] = m.group(2)
    return result


def get_stable_deb_packages(base_url, distrib, arch="amd64"):
    """Return {pkg_name: version} for packages already in the Centreon stable DEB repo.

    All distribs of the same family (debian / ubuntu) share the same pool folder;
    files are distinguished by the distrib suffix in their version string and the
    arch in their filename.

    Example filename: libjson-path-perl_1.0.6+deb12u1_amd64.deb
      → pkg_name = "libjson-path-perl", version = "1.0.6"
    """
    repo = "ubuntu-plugins-stable" if distrib in UBUNTU_DISTRIBS else "apt-plugins-stable"
    if repo not in _deb_pool_cache:
        _deb_pool_cache[repo] = _artifactory_list_folder(
            base_url, f"{repo}/pool/{CPAN_MODULE_NAME}"
        )
    files  = _deb_pool_cache[repo]
    suffix = DEB_DISTRIB_SUFFIX.get(distrib, "")
    result = {}
    for fname in files:
        if not fname.endswith(f"_{arch}.deb"):
            continue
        if suffix and suffix not in fname:
            continue
        # Parse: {pkg_name}_{version}+{suffix}_{arch}.deb  or  ..._{version}-{suffix}_...
        m = re.match(r"^(.+?)_([0-9v][0-9.]*)[+\-].+_[^_]+\.deb$", fname)
        if m:
            result[m.group(1)] = m.group(2)
    return result


def run_check(args, libraries):
    """Check mode: query the local package manager and write a partial-matrix JSON."""
    pkg_manager = detect_package_manager()
    if pkg_manager is None:
        print("ERROR: neither dnf nor apt-get found", file=sys.stderr)
        sys.exit(1)

    check_distrib = args.check_distrib
    print(f"Distrib: {check_distrib} | package manager: {pkg_manager}", file=sys.stderr)

    if pkg_manager == "rpm":
        # Filter libs that target this RPM distrib
        libs_for_distrib = [
            lib for lib in libraries
            if "rpm" in lib and check_distrib in [
                d.strip()
                for d in lib["rpm"].get("build_distribs", RPM_DEFAULT_BUILD_DISTRIBS).split(",")
                if d.strip()
            ]
        ]
        lib_names = [lib["name"] for lib in libs_for_distrib]
        print(f"Fetching CPAN info for {len(lib_names)} libs…", file=sys.stderr)
        cpanm_infos = get_cpanm_infos(lib_names)  # {name: (dist_name, version)}

        print(f"Checking {len(lib_names)} libs in official RPM repo ({check_distrib})…", file=sys.stderr)
        available = check_rpm(lib_names)

        names = []
        lib_includes = []
        for lib in libs_for_distrib:
            name = lib["name"]
            rpm = lib["rpm"]
            found = available.get(name)
            if found is not None:
                cpan_version = cpanm_infos.get(name, ("", ""))[1]
                required_version = rpm.get("version", "") or cpan_version
                if versions_match(found, required_version):
                    print(f"  Skip {name}: official repo has v{found}", file=sys.stderr)
                    continue
            names.append(name)
            cpan_info = cpanm_infos.get(name, ("", ""))
            lib_includes.append({"name": name, **rpm,
                                  "cpan_dist_name": cpan_info[0],
                                  "cpan_version":   cpan_info[1]})

        result = {
            "distrib": check_distrib,
            "type": "rpm",
            "names": names,
            "lib_includes": lib_includes,
        }

    else:  # deb
        covered_build_names = DEB_CHECK_DISTRIB_TO_BUILD_NAMES.get(check_distrib, [check_distrib])

        # Filter libs that target at least one build_name covered by this check_distrib
        libs_for_distrib = [
            lib for lib in libraries
            if "deb" in lib and any(
                bn in covered_build_names
                for bn in [
                    b.strip()
                    for b in lib["deb"].get("build_names", DEB_DEFAULT_BUILD_NAMES).split(",")
                    if b.strip()
                ]
            )
        ]
        lib_names = [lib["name"] for lib in libs_for_distrib]
        print(f"Fetching CPAN info for {len(lib_names)} libs…", file=sys.stderr)
        cpanm_infos = get_cpanm_infos(lib_names)  # {name: (dist_name, version)}

        lib_to_pkg = {
            name: dist_to_deb_package(cpanm_infos.get(name, ("", ""))[0], name)
            for name in lib_names
        }
        print(f"Checking {len(lib_to_pkg)} libs in official DEB repo ({check_distrib})…", file=sys.stderr)
        available = check_deb(lib_to_pkg)

        names = []
        lib_includes = []
        for lib in libs_for_distrib:
            name = lib["name"]
            deb = lib["deb"]
            found = available.get(name)
            if found is not None:
                # Use the version pinned in cpan-libraries.json if set,
                # otherwise compare against the current CPAN version.
                cpan_version = cpanm_infos.get(name, ("", ""))[1]
                required_version = deb.get("version", "") or cpan_version
                if versions_match(found, required_version):
                    print(f"  Skip {name}: official repo has v{found}", file=sys.stderr)
                    continue
            names.append(name)
            cpan_info = cpanm_infos.get(name, ("", ""))
            lib_includes.append({"name": name, **deb,
                                  "cpan_dist_name": cpan_info[0],
                                  "cpan_version":   cpan_info[1]})

        result = {
            "distrib": check_distrib,
            "type": "deb",
            "names": names,
            "lib_includes": lib_includes,
        }

    print(f"→ {len(names)} libs to package for {check_distrib}", file=sys.stderr)
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Results written to {args.output}", file=sys.stderr)


# ══════════════════════════════════════════════════════════════════════════════
# MERGE MODE – runs on the CI runner after all check jobs
# ══════════════════════════════════════════════════════════════════════════════

def merge_matrices(partial_matrices_dir, libraries, artifactory_url=None):
    """Merge partial matrices from check jobs into final RPM and DEB matrices.

    Generates flat include-only matrices: one entry per (lib, distrib/build_name)
    combination that actually needs to be built. No 2D cross-product, no excludes.

    When artifactory_url is provided, packages already present in the Centreon
    stable repository at the expected version are also filtered out.
    """
    rpm_partials = {}  # distrib → partial matrix data
    deb_partials = {}  # check_distrib → partial matrix data

    if partial_matrices_dir and os.path.isdir(partial_matrices_dir):
        for fname in sorted(os.listdir(partial_matrices_dir)):
            if not fname.endswith(".json"):
                continue
            with open(os.path.join(partial_matrices_dir, fname)) as f:
                data = json.load(f)
            ptype   = data.get("type", "")
            distrib = data.get("distrib", "")
            if ptype == "rpm":
                rpm_partials[distrib] = data
                print(f"  Loaded RPM partial for {distrib}: {len(data.get('names', []))} libs to build", file=sys.stderr)
            elif ptype == "deb":
                deb_partials[distrib] = data
                print(f"  Loaded DEB partial for {distrib}: {len(data.get('names', []))} libs to build", file=sys.stderr)

    have_partials = bool(rpm_partials or deb_partials)

    # Build per-lib extras lookup (cpan_version + cpan_dist_name) from partial lib_includes
    def _build_extras(partials):
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

    rpm_lib_extras = _build_extras(rpm_partials)  # distrib      → {name → extras}
    deb_lib_extras = _build_extras(deb_partials)  # check_distrib → {name → extras}

    # Optionally query Centreon stable repository
    rpm_stable: dict = {}  # distrib → {cpan_dist_name: version}
    deb_stable: dict = {}  # (check_distrib, arch) → {pkg_name: version}
    if artifactory_url:
        print("Checking Centreon stable repository…", file=sys.stderr)
        for distrib in RPM_DISTRIBS:
            rpm_stable[distrib] = get_stable_rpm_packages(artifactory_url, distrib)
            print(f"  RPM {distrib}: {len(rpm_stable[distrib])} packages in stable",
                  file=sys.stderr)
        seen_deb_keys: set = set()
        for bn_entry in DEB_BUILD_NAME_INCLUDES:
            check_distrib = DEB_IMAGE_TO_CHECK_DISTRIB[bn_entry["image"]]
            arch          = bn_entry.get("arch", "amd64")
            key           = (check_distrib, arch)
            if key not in seen_deb_keys:
                seen_deb_keys.add(key)
                deb_stable[key] = get_stable_deb_packages(artifactory_url, check_distrib, arch)
                print(f"  DEB {check_distrib} {arch}: {len(deb_stable[key])} packages in stable",
                      file=sys.stderr)

    # ── RPM matrix ────────────────────────────────────────────────────────────
    rpm_includes = []
    for lib in libraries:
        if "rpm" not in lib:
            continue
        name = lib["name"]
        rpm  = lib["rpm"]
        build_distribs = [
            d.strip()
            for d in rpm.get("build_distribs", RPM_DEFAULT_BUILD_DISTRIBS).split(",")
            if d.strip()
        ]
        for distrib_entry in RPM_DISTRIB_INCLUDES:
            distrib = distrib_entry["distrib"]
            if distrib not in build_distribs:
                continue
            if have_partials:
                if distrib in rpm_partials:
                    if name not in set(rpm_partials[distrib].get("names", [])):
                        print(f"  Skip RPM {name}/{distrib}: already in official repo", file=sys.stderr)
                        continue
                else:
                    print(f"  WARNING: no partial for RPM {distrib}, including {name}", file=sys.stderr)
            extras         = rpm_lib_extras.get(distrib, {}).get(name, {})
            cpan_version   = extras.get("cpan_version",   "")
            cpan_dist_name = extras.get("cpan_dist_name", "")
            if artifactory_url and cpan_dist_name:
                stable_version = rpm_stable.get(distrib, {}).get(cpan_dist_name)
                if stable_version is not None:
                    required = rpm.get("version", "") or cpan_version
                    if versions_match(stable_version, required):
                        print(f"  Skip RPM {name}/{distrib}: Centreon stable has v{stable_version}",
                              file=sys.stderr)
                        continue
            rpm_includes.append({**RPM_DEFAULTS, **distrib_entry, "name": name,
                                  "cpan_version": cpan_version,
                                  **{k: v for k, v in rpm.items() if k != "build_distribs"}})

    rpm_matrix = {"include": rpm_includes}

    # ── DEB matrix ────────────────────────────────────────────────────────────
    deb_includes = []
    for lib in libraries:
        if "deb" not in lib:
            continue
        name = lib["name"]
        deb  = lib["deb"]
        build_names = [
            b.strip()
            for b in deb.get("build_names", DEB_DEFAULT_BUILD_NAMES).split(",")
            if b.strip()
        ]
        for bn_entry in DEB_BUILD_NAME_INCLUDES:
            build_name    = bn_entry["build_name"]
            check_distrib = DEB_IMAGE_TO_CHECK_DISTRIB.get(bn_entry["image"], "")
            if build_name not in build_names:
                continue
            if have_partials:
                if check_distrib in deb_partials:
                    if name not in set(deb_partials[check_distrib].get("names", [])):
                        print(f"  Skip DEB {name}/{build_name}: already in official repo", file=sys.stderr)
                        continue
                else:
                    print(f"  WARNING: no partial for DEB {check_distrib}, including {name}/{build_name}", file=sys.stderr)
            extras         = deb_lib_extras.get(check_distrib, {}).get(name, {})
            cpan_version   = extras.get("cpan_version",   "")
            cpan_dist_name = extras.get("cpan_dist_name", "")
            if artifactory_url and cpan_dist_name:
                arch           = bn_entry.get("arch", "amd64")
                pkg_name       = dist_to_deb_package(cpan_dist_name)
                stable_version = deb_stable.get((check_distrib, arch), {}).get(pkg_name)
                if stable_version is not None:
                    required = deb.get("version", "") or cpan_version
                    if versions_match(stable_version, required):
                        print(f"  Skip DEB {name}/{build_name}: Centreon stable has v{stable_version}",
                              file=sys.stderr)
                        continue
            deb_includes.append({**DEB_DEFAULTS, **bn_entry, "name": name,
                                  "cpan_version": cpan_version,
                                  **{k: v for k, v in deb.items() if k != "build_names"}})

    deb_matrix = {"include": deb_includes}

    return rpm_matrix, deb_matrix


# ── Entry point ────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Generate CI matrices / check official repos for perl-cpan-libraries."
    )
    parser.add_argument("json_file", help="Path to cpan-libraries.json")

    # Check mode
    parser.add_argument(
        "--check-distrib", metavar="DISTRIB",
        help="[Check mode] Name of the current distrib (e.g. el8, bookworm). "
             "Queries the local package manager and writes a partial-matrix JSON to --output.",
    )
    parser.add_argument(
        "--output", metavar="FILE",
        help="[Check mode] Path for the partial-matrix JSON output file.",
    )

    # Merge mode
    parser.add_argument(
        "--partial-matrices-dir", metavar="DIR",
        help="[Merge mode] Directory containing the partial-matrix JSON files produced "
             "by --check-distrib runs. When absent, matrices are generated without "
             "official-repo filtering (useful for local debugging).",
    )
    parser.add_argument(
        "--artifactory-url", metavar="URL",
        help="[Merge mode] Base URL of the public Artifactory instance "
             "(e.g. https://packages.centreon.com). When provided, packages already "
             "present in the Centreon stable repository at the expected version are "
             "skipped (not rebuilt). Requires partial-matrix JSON files that contain "
             "cpan_dist_name (produced by recent check-distrib runs).",
    )

    args = parser.parse_args()

    with open(args.json_file) as f:
        libraries = json.load(f)["libraries"]

    # ── Check mode ─────────────────────────────────────────────────────────────
    if args.check_distrib:
        if not args.output:
            parser.error("--output is required with --check-distrib")
        run_check(args, libraries)
        return

    # ── Merge mode ─────────────────────────────────────────────────────────────
    rpm_matrix, deb_matrix = merge_matrices(
        args.partial_matrices_dir, libraries,
        artifactory_url=args.artifactory_url,
    )

    github_output = os.environ.get("GITHUB_OUTPUT", "")
    if github_output:
        with open(github_output, "a") as f:
            f.write(f"matrix_rpm={json.dumps(rpm_matrix)}\n")
            f.write(f"matrix_deb={json.dumps(deb_matrix)}\n")
    else:
        print("=== RPM matrix ===")
        print(json.dumps(rpm_matrix, indent=2))
        print("\n=== DEB matrix ===")
        print(json.dumps(deb_matrix, indent=2))


if __name__ == "__main__":
    main()