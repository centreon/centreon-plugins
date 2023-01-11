#!/usr/bin/env python3

from sys import argv
import re
import os
import json

common = argv[1] == 'true'
packages = argv[2]
plugins = argv[3]

print(plugins)

list_plugins_changes = set()
list_plugins_dir = set()
list_packages = set()

if not common:
    for plugin in plugins.split(' '):
        list_plugins_changes.add(plugin.strip('/'))
        try:
            found = re.search('(.*)\/mode\/.*', plugin).group(1)
            list_plugins_dir.add(found)
        except AttributeError:
            try:
                found = re.search('(.*)\/plugin.pm', plugin).group(1)
                list_plugins_dir.add(found)
            except AttributeError:
                pass
    updated_packages = packages.split(' ')

print("list plugins")
print(*list_plugins_changes)
print("end list plugins")

for filepath in os.popen('find packaging -type f -name pkg.json').read().split('\n')[0:-1]:
        packaging_file = open(filepath)
        packaging = json.load(packaging_file)
        packaging_file.close()
        packaging_path = re.search('.*\/(centreon-plugin-.*)\/pkg.json', filepath).group(1)
        if not packaging_path == packaging["pkg_name"]:
            packaging_path = packaging_path + "=>" + packaging["pkg_name"]
        if common or filepath in updated_packages:
            list_packages.add(packaging_path)
        else:
            for pkg_file in packaging["files"]:
                pkg_file_dir = 'centreon-plugins/' + pkg_file.strip('/')
                try:
                    found = re.search('(.*)\/(?:plugin\.pm|mode\/.+)', pkg_file).group(1)
                    pkg_file_dir = 'centreon-plugins/' + found
                except AttributeError:
                    pass
                print(pkg_file_dir)
                if pkg_file_dir in list_plugins_changes:
                    print("bonjour " + pkg_file_dir)
                    list_packages.add(packaging_path)
print("list packages")
print(*list_packages)
print("end list packages")
