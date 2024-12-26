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
    packaging_path = packaging["pkg_name"]

    directory_path = re.search('^(.+)\/pkg.json', filepath).group(1)

    if common:
        # if the common flag is true, then all packages are included
        list_packages.add(packaging_path)
    elif directory_path in packages:
        # if a package file is changed or created, then the package is included
        list_packages.add(packaging_path)
    else:
        # if we don't build all the plugins and no modification have been made to this package's 
        # specification, then examine if its source code has been changed
        for pkg_file in packaging["files"]:
            # for each source code file or directory included in the current package
            pkg_file_dir = pkg_file.strip('/').removeprefix('src/')
            # the current package is impacted by the changes if one of the changed files
            # is located inside one of the directories of the package
            for modified_file in list_plugins:
                # if the beginning of the changed file path includes one of the package's directories
                if modified_file.find(pkg_file_dir) == 0:
                    # then the package is included
                    list_packages.add(packaging_path)
                    break

print(*list_packages)
