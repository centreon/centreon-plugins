#!/usr/bin/env python3
"""Merge partial-matrix JSONs into final RPM and DEB CI matrices.

Reads the partial-matrix JSON files produced by check-official-repos.py and
generates flat include-only matrices written to GITHUB_OUTPUT (or printed to
stdout when GITHUB_OUTPUT is not set, useful for local debugging).

Optionally filters out packages already present in the Centreon stable
Artifactory repository at the expected version.

Usage:
    # CI (after all check-official-repos jobs)
    python3 generate-matrices.py \\
        --partial-matrices-dir official-repos/ \\
        --artifactory-url https://packages.centreon.com \\
        .github/packaging/cpan-libraries.json

    # Local debug (no filtering, cpanm used for version info if available)
    python3 generate-matrices.py .github/packaging/cpan-libraries.json
"""

import argparse
import json
import os
import shutil
import sys

from cpan_matrix_lib import (
    RPM_DEFAULTS,
    DEB_DEFAULTS,
    RPM_DISTRIB_INCLUDES,
    DEB_BUILD_NAME_INCLUDES,
    RPM_DISTRIBS,
    DEB_IMAGE_TO_CHECK_DISTRIB,
    DEB_CHECK_DISTRIB_TO_BUILD_NAMES,
    RPM_DEFAULT_BUILD_DISTRIBS,
    DEB_DEFAULT_BUILD_NAMES,
    csv_split,
    versions_match,
    extras_from_partials,
    get_cpanm_infos,
    dist_to_deb_package,
    get_stable_rpm_packages,
    get_stable_deb_packages,
)


def merge_matrices(partial_matrices_dir, libraries, artifactory_url=None):
    """Return (rpm_matrix, deb_matrix) as dicts with an 'include' list each.

    Generates flat include-only matrices: one entry per (lib, distrib/build_name)
    combination that actually needs to be built. No 2D cross-product, no excludes.
    """
    rpm_partials = {}  # distrib      → partial matrix data
    deb_partials = {}  # check_distrib → partial matrix data

    if partial_matrices_dir and os.path.isdir(partial_matrices_dir):
        for fname in sorted(os.listdir(partial_matrices_dir)):
            if not fname.endswith(".json"):
                continue
            base_real = os.path.realpath(partial_matrices_dir)
            target_real = os.path.realpath(os.path.join(partial_matrices_dir, fname))
            if os.path.commonpath([base_real, target_real]) != base_real:
                raise Exception("Invalid file path")
            with open(target_real) as f:
                data = json.load(f)
            ptype   = data.get("type", "")
            distrib = data.get("distrib", "")
            if ptype == "rpm":
                rpm_partials[distrib] = data
                print(f"  Loaded RPM partial for {distrib}: {len(data.get('names', []))} libs to build",
                      file=sys.stderr)
            elif ptype == "deb":
                deb_partials[distrib] = data
                print(f"  Loaded DEB partial for {distrib}: {len(data.get('names', []))} libs to build",
                      file=sys.stderr)

    have_partials    = bool(rpm_partials or deb_partials)
    rpm_lib_extras   = extras_from_partials(rpm_partials)  # distrib      → {name → extras}
    deb_lib_extras   = extras_from_partials(deb_partials)  # check_distrib → {name → extras}
    # Distrib metadata (family, suffix) from parse-distrib action outputs, carried in partial JSONs
    deb_distrib_meta = {
        d: {"family": data.get("family", "debian"), "suffix": data.get("suffix", "")}
        for d, data in deb_partials.items()
    }
    # Pre-compute name sets for O(1) membership tests in the matrix loops below
    rpm_names_by_distrib = {d: set(data.get("names", [])) for d, data in rpm_partials.items()}
    deb_names_by_distrib = {d: set(data.get("names", [])) for d, data in deb_partials.items()}

    # When no partial matrices are available (local debug), call cpanm directly
    # to populate cpan_version / cpan_dist_name if cpanm is installed.
    if not have_partials and shutil.which("cpanm"):
        all_names = [lib["name"] for lib in libraries if "rpm" in lib or "deb" in lib]
        print(f"No partial matrices — fetching CPAN info for {len(all_names)} libs…",
              file=sys.stderr)
        cpanm_extras = {
            name: {"cpan_dist_name": d, "cpan_version": v}
            for name, (d, v) in get_cpanm_infos(all_names).items()
        }
        for distrib in RPM_DISTRIBS:
            rpm_lib_extras.setdefault(distrib, {}).update(cpanm_extras)
        for check_distrib in DEB_CHECK_DISTRIB_TO_BUILD_NAMES:
            deb_lib_extras.setdefault(check_distrib, {}).update(cpanm_extras)

    # Optionally query Centreon stable repository
    rpm_stable: dict = {}  # distrib → {cpan_dist_name: version}
    deb_stable: dict = {}  # (check_distrib, arch) → {pkg_name: version}
    if artifactory_url:
        print("Checking Centreon stable repository…", file=sys.stderr)
        for distrib in RPM_DISTRIBS:
            rpm_stable[distrib] = get_stable_rpm_packages(artifactory_url, distrib)
            print(f"  RPM {distrib}: {len(rpm_stable[distrib])} packages in stable", file=sys.stderr)
        seen: set = set()
        for bn_entry in DEB_BUILD_NAME_INCLUDES:
            check_distrib = DEB_IMAGE_TO_CHECK_DISTRIB[bn_entry["image"]]
            arch          = bn_entry.get("arch", "amd64")
            key           = (check_distrib, arch)
            if key not in seen:
                seen.add(key)
                meta = deb_distrib_meta.get(check_distrib, {})
                deb_stable[key] = get_stable_deb_packages(
                    artifactory_url, check_distrib, arch,
                    family=meta.get("family", "debian"),
                    suffix=meta.get("suffix", ""),
                )
                print(f"  DEB {check_distrib} {arch}: {len(deb_stable[key])} packages in stable",
                      file=sys.stderr)

    # ── RPM matrix ────────────────────────────────────────────────────────────
    rpm_includes = []
    for lib in libraries:
        if "rpm" not in lib:
            continue
        name = lib["name"]
        rpm  = lib["rpm"]
        build_distribs = csv_split(rpm.get("build_distribs", RPM_DEFAULT_BUILD_DISTRIBS))
        for distrib_entry in RPM_DISTRIB_INCLUDES:
            distrib = distrib_entry["distrib"]
            if distrib not in build_distribs:
                continue
            if have_partials:
                if distrib in rpm_names_by_distrib:
                    if name not in rpm_names_by_distrib[distrib]:
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

    # ── DEB matrix ────────────────────────────────────────────────────────────
    deb_includes = []
    for lib in libraries:
        if "deb" not in lib:
            continue
        name = lib["name"]
        deb  = lib["deb"]
        build_names = csv_split(deb.get("build_names", DEB_DEFAULT_BUILD_NAMES))
        for bn_entry in DEB_BUILD_NAME_INCLUDES:
            build_name    = bn_entry["build_name"]
            check_distrib = DEB_IMAGE_TO_CHECK_DISTRIB.get(bn_entry["image"], "")
            if build_name not in build_names:
                continue
            if have_partials:
                if check_distrib in deb_names_by_distrib:
                    if name not in deb_names_by_distrib[check_distrib]:
                        print(f"  Skip DEB {name}/{build_name}: already in official repo", file=sys.stderr)
                        continue
                else:
                    print(f"  WARNING: no partial for DEB {check_distrib}, including {name}/{build_name}",
                          file=sys.stderr)
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

    return {"include": rpm_includes}, {"include": deb_includes}


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("json_file", help="Path to cpan-libraries.json")
    parser.add_argument(
        "--partial-matrices-dir", metavar="DIR",
        help="Directory containing the partial-matrix JSON files produced by "
             "check-official-repos.py. When absent, matrices are generated without "
             "official-repo filtering (useful for local debugging).",
    )
    parser.add_argument(
        "--artifactory-url", metavar="URL",
        help="Base URL of the public Artifactory instance "
             "(e.g. https://packages.centreon.com). When provided, packages already "
             "present in the Centreon stable repository at the expected version are "
             "skipped (not rebuilt).",
    )
    args = parser.parse_args()

    with open(args.json_file) as f:
        libraries = json.load(f)["libraries"]

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
