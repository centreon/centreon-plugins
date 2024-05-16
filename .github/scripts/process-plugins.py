#!/usr/bin/env python3

from sys import argv
import re
import os
import json

common = argv[1] == 'true'

with open('package_directories.txt') as f:
    line_packages = f.readline().strip('\n')
n = len(line_packages)
a = line_packages[1:n-1]
input_packages = a.split(',')
packages = set()
for package in input_packages:
    packages.add(package.strip('"/').removeprefix('src/'))

with open('plugins.txt') as f:
    line_plugins = f.readline().strip('\n')
n = len(line_plugins)
a = line_plugins[1:n-1]
input_plugins = a.split(',')
plugins = set()
for plugin in input_plugins:
    plugins.add(plugin.strip('"/').removeprefix('src/'))

list_plugins = set()
list_packages = set()

for plugin in plugins:
    list_plugins.add(plugin)
    try:
        found = re.search('(.*)\/(?:plugin\.pm|(?:lib|mode|custom)\/.+)', plugin).group(1)
        list_plugins.add(found)
    except AttributeError:
        pass

for filepath in os.popen('find packaging -type f -name pkg.json').read().split('\n')[0:-1]:
    packaging_file = open(filepath)
    packaging = json.load(packaging_file)
    packaging_file.close()
    packaging_path = re.search('.*\/(centreon-plugin-.*)\/pkg.json', filepath).group(1)

    if not packaging_path == packaging["pkg_name"]:
        packaging_path = packaging["pkg_name"]

    directory_path = re.search('^(.+)\/pkg.json', filepath).group(1)

    if common:
        list_packages.add(packaging_path)
    elif directory_path in packages:
        list_packages.add(packaging_path)
    else:
        for pkg_file in packaging["files"]:
            pkg_file_dir = pkg_file.strip('/').removeprefix('src/')
            if pkg_file_dir in list_plugins:
                list_packages.add(packaging_path)

print(*list_packages)
