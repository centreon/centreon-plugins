#!/usr/bin/env python3

from sys import argv
import json
import subprocess

common = argv[1] == 'true'

list_plugins = {}
package_plugins = False
test_plugins = False


def add_package_info(packaging_file, build=True, test=True):
    global package_plugins, test_plugins
    if build:
        package_plugins = True
    if test:
        test_plugins = True
    with open(packaging_file) as package_file:
        packaging = json.load(package_file)
        plugin_paths = []
        for plugin_file in packaging['files']:
            if not (plugin_file.startswith("centreon") or plugin_file.startswith("example") or plugin_file.startswith("snmp_standard")):
                plugin_paths.append(plugin_file)
        if packaging['pkg_name'] not in list_plugins:
            list_plugins[packaging['pkg_name']] = {
                "command": packaging['plugin_name'],
                "paths": plugin_paths,
                "build": build,
                "test": test
            }


def get_pack_from_path(path):
    cmd = ["grep", "-RIl", path, "packaging", "--include", "pkg.json"]
    res = subprocess.run(cmd, capture_output=True, text=True, check=False)
    return res.stdout.splitlines()


if __name__ == '__main__':
    if common:
        cmd = ["find", "packaging", "-type", "f", "-name", "pkg.json"]
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        for filepath in res.stdout.strip().split('\n'):
            add_package_info(filepath)
    else:
        with open('packages_directories.json') as packages_directories_file:
            packages = json.load(packages_directories_file)
            for package in packages:
                add_package_info(package + "/pkg.json")

        with open('plugins_directories.json') as plugins_directories_file:
            plugins = json.load(plugins_directories_file)
            for plugin in plugins:
                plugin_path = plugin.removeprefix('src/')
                for pack_file in get_pack_from_path(plugin_path):
                    add_package_info(pack_file)

        with open('tests_directories.json') as tests_directories_file:
            tests = json.load(tests_directories_file)
            for test in tests:
                test_path = test.removeprefix('tests/')
                for pack_file in get_pack_from_path(test_path):
                    add_package_info(pack_file, False)

    with open('plugins.json', 'w') as outfile:
        json.dump(list_plugins, outfile, indent=4)

print(package_plugins, test_plugins)