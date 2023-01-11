#!/usr/bin/env python3

from sys import argv
import re
import os
import json

common = argv[1] == 'true'

n = len(argv[2])
a = argv[2][1:n-1]
packages = a.split(', ')

n = len(argv[3])
a = argv[3][1:n-1]
plugins = a.split(', ')

def remove_prefix(text, prefix):
    if text.startswith(prefix):
        return text[len(prefix):]
    return text

list_plugins_dir = set()
list_plugins = set()
list_packages = set()

for plugin in plugins.split(' '):
    print("with prefix " + plugin)
    plugin = remove_prefix(plugin.strip('/'), 'centreon-plugins/')
    list_plugins.add(plugin)
    print("without prefix " + plugin)
    try:
        found = re.search('(.*)\/(?:plugin\.pm|mode\/.+)', plugin).group(1)
        print(found)
        list_plugins.add(found)
    except AttributeError:
        pass

updated_packages = packages.split(' ')

#print("list plugins")
#print(*list_plugins_dir)
#print("end list plugins")

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
                pkg_file_dir = remove_prefix(pkg_file.strip('/'), 'centreon-plugins/')
                #try:
                #    found = re.search('(.*)\/(?:plugin\.pm|mode\/.+)', pkg_file).group(1)
                #    pkg_file_dir = found.strip('/')
                #except AttributeError:
                #    pass
                #print(pkg_file_dir)
                if pkg_file_dir in list_plugins:
                    print("bonjour " + pkg_file_dir)
                    list_packages.add(packaging_path)

#print("list packages")
#print(*list_packages)
#print("end list packages")
