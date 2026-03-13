#!/usr/bin/env python3
"""Check official distribution repositories for already-packaged CPAN libs.

Runs inside a distribution container (el8/el9/el10, bullseye, bookworm, …).
Queries the local package manager, filters out libs already packaged at the
expected version, and writes a partial-matrix JSON consumed by generate-matrices.py.

Usage:
    python3 check-official-repos.py \\
        --distrib bookworm \\
        --output official-repos/partial-matrix-bookworm.json \\
        .github/packaging/cpan-libraries.json
"""

import argparse
import json
import os
import sys

from cpan_matrix_lib import (
    RPM_DEFAULT_BUILD_DISTRIBS,
    DEB_DEFAULT_BUILD_NAMES,
    DEB_CHECK_DISTRIB_TO_BUILD_NAMES,
    csv_split,
    get_cpanm_infos,
    dist_to_deb_package,
    check_rpm,
    check_deb,
    detect_package_manager,
    filter_to_includes,
)


def run_check(distrib, output_path, libraries, separator="", suffix="", family=""):
    pkg_manager = detect_package_manager()
    if pkg_manager is None:
        print("ERROR: neither dnf nor apt-get found", file=sys.stderr)
        sys.exit(1)

    print(f"Distrib: {distrib} | package manager: {pkg_manager}", file=sys.stderr)

    if pkg_manager == "rpm":
        libs_for_distrib = [
            lib for lib in libraries
            if "rpm" in lib
            and distrib in csv_split(lib["rpm"].get("build_distribs", RPM_DEFAULT_BUILD_DISTRIBS))
        ]
        lib_names = [lib["name"] for lib in libs_for_distrib]
        print(f"Fetching CPAN info for {len(lib_names)} libs…", file=sys.stderr)
        cpanm_infos = get_cpanm_infos(lib_names)
        print(f"Checking {len(lib_names)} libs in official RPM repo ({distrib})…", file=sys.stderr)
        available = check_rpm(lib_names)
    else:
        covered = DEB_CHECK_DISTRIB_TO_BUILD_NAMES.get(distrib, [distrib])
        libs_for_distrib = [
            lib for lib in libraries
            if "deb" in lib
            and any(bn in covered for bn in csv_split(lib["deb"].get("build_names", DEB_DEFAULT_BUILD_NAMES)))
        ]
        lib_names = [lib["name"] for lib in libs_for_distrib]
        print(f"Fetching CPAN info for {len(lib_names)} libs…", file=sys.stderr)
        cpanm_infos = get_cpanm_infos(lib_names)
        lib_to_pkg = {
            name: dist_to_deb_package(cpanm_infos.get(name, ("", ""))[0], name)
            for name in lib_names
        }
        print(f"Checking {len(lib_to_pkg)} libs in official DEB repo ({distrib})…", file=sys.stderr)
        available = check_deb(lib_to_pkg)

    names, lib_includes = filter_to_includes(libs_for_distrib, pkg_manager, cpanm_infos, available)

    result = {
        "distrib":      distrib,
        "type":         pkg_manager,
        "separator":    separator,
        "suffix":       suffix,
        "family":       family,
        "names":        names,
        "lib_includes": lib_includes,
    }
    print(f"→ {len(names)} libs to package for {distrib}", file=sys.stderr)
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    if ".." in output_path:
        raise Exception("Invalid file path")
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Results written to {output_path}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("json_file", help="Path to cpan-libraries.json")
    parser.add_argument("--distrib", required=True, metavar="DISTRIB",
                        help="Name of the current distrib (e.g. el8, bookworm)")
    parser.add_argument("--output", required=True, metavar="FILE",
                        help="Path for the partial-matrix JSON output file")
    parser.add_argument("--separator", default="", metavar="SEP",
                        help="Package version/distrib separator (from parse-distrib action)")
    parser.add_argument("--suffix", default="", metavar="SUFFIX",
                        help="Distrib suffix in package name (from parse-distrib action)")
    parser.add_argument("--family", default="", metavar="FAMILY",
                        help="Distrib family: el, debian or ubuntu (from parse-distrib action)")
    args = parser.parse_args()

    with open(args.json_file) as f:
        libraries = json.load(f)["libraries"]

    run_check(args.distrib, args.output, libraries,
              separator=args.separator, suffix=args.suffix, family=args.family)


if __name__ == "__main__":
    main()
