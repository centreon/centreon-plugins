#!/usr/bin/env python3
"""Generate GitHub Actions matrices for perl-cpan-libraries workflow from JSON definition."""

import json
import os
import sys


RPM_DEFAULTS = {
    "build_distribs": "el8,el9,el10",
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
    "build_names": "bullseye-amd64,bookworm,trixie,jammy,noble",
    "deb_dependencies": "",
    "deb_provides": "",
    "version": "",
    "use_dh_make_perl": "true",
    "no-auto-depends": "false",
    "preinstall_cpanlibs": "",
    "revision": "1",
}

RPM_DISTRIB_INCLUDES = [
    {"distrib": "el8", "package_extension": "rpm", "image": "packaging-plugins-alma8"},
    {"distrib": "el9", "package_extension": "rpm", "image": "packaging-plugins-alma9"},
    {"distrib": "el10", "package_extension": "rpm", "image": "packaging-plugins-alma10"},
]

DEB_BUILD_NAME_INCLUDES = [
    {"build_name": "bullseye-amd64", "distrib": "bullseye", "package_extension": "deb", "image": "packaging-plugins-bullseye"},
    {"build_name": "bookworm", "distrib": "bookworm", "package_extension": "deb", "image": "packaging-plugins-bookworm"},
    {"build_name": "trixie", "distrib": "trixie", "package_extension": "deb", "image": "packaging-plugins-trixie"},
    {"build_name": "jammy", "distrib": "jammy", "package_extension": "deb", "image": "packaging-plugins-jammy"},
    {"build_name": "noble", "distrib": "noble", "package_extension": "deb", "image": "packaging-plugins-noble"},
    {
        "build_name": "bullseye-arm64",
        "distrib": "bullseye",
        "package_extension": "deb",
        "image": "packaging-plugins-bullseye-arm64",
        "arch": "arm64",
        "runner_name": "ubuntu-24.04-arm",
    },
]


def generate_matrices(json_file):
    with open(json_file) as f:
        data = json.load(f)

    libraries = data["libraries"]

    # --- RPM matrix ---
    rpm_names = [lib["name"] for lib in libraries if "rpm" in lib]
    rpm_includes = [RPM_DEFAULTS] + RPM_DISTRIB_INCLUDES

    for lib in libraries:
        if "rpm" not in lib or not lib["rpm"]:
            continue
        entry = {"name": lib["name"]}
        entry.update(lib["rpm"])
        rpm_includes.append(entry)

    rpm_matrix = {
        "distrib": ["el8", "el9", "el10"],
        "name": rpm_names,
        "include": rpm_includes,
    }

    # --- DEB matrix ---
    deb_images = [
        "packaging-plugins-bullseye",
        "packaging-plugins-bookworm",
        "packaging-plugins-trixie",
        "packaging-plugins-jammy",
        "packaging-plugins-noble",
        "packaging-plugins-bullseye-arm64",
    ]
    deb_names = [lib["name"] for lib in libraries if "deb" in lib]
    deb_includes = [DEB_DEFAULTS] + DEB_BUILD_NAME_INCLUDES

    for lib in libraries:
        if "deb" not in lib or not lib["deb"]:
            continue
        entry = {"name": lib["name"]}
        entry.update(lib["deb"])
        deb_includes.append(entry)

    deb_matrix = {
        "image": deb_images,
        "name": deb_names,
        "include": deb_includes,
    }

    return rpm_matrix, deb_matrix


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <cpan-libraries.json>", file=sys.stderr)
        sys.exit(1)

    rpm_matrix, deb_matrix = generate_matrices(sys.argv[1])

    github_output = os.environ.get("GITHUB_OUTPUT", "")
    if github_output:
        with open(github_output, "a") as f:
            f.write(f"matrix_rpm={json.dumps(rpm_matrix)}\n")
            f.write(f"matrix_deb={json.dumps(deb_matrix)}\n")
    else:
        # Local debug: pretty-print both matrices
        print("=== RPM matrix ===")
        print(json.dumps(rpm_matrix, indent=2))
        print("\n=== DEB matrix ===")
        print(json.dumps(deb_matrix, indent=2))