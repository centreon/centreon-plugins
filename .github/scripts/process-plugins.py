#!/usr/bin/env python3

from sys import argv
import re
import os
import json

common = argv[1] == 'true'

def clean_inputs(n):
    return n.strip('"/').removeprefix('centreon-plugins/')

n = len(argv[2])
a = argv[2][1:n-1]
packages = a.split(',')
packages = map(clean_inputs, packages)

n = len(argv[3])
a = argv[3][1:n-1]
plugins = a.split(',')
plugins = map(clean_inputs, plugins)

list_plugins = set()
list_packages = set()

for plugin in plugins:
    list_plugins.add(plugin)
    try:
        found = re.search('(.*)\/(?:plugin\.pm|mode\/.+)', plugin).group(1)
        list_plugins.add(found)
    except AttributeError:
        pass


if 'packaging/centreon-plugin-Cloud-Azure-Network-TrafficManager' in packages:
    print(list(packages))

for filepath in os.popen('find packaging -type f -name pkg.json').read().split('\n')[0:-1]:
    packaging_file = open(filepath)
    packaging = json.load(packaging_file)
    packaging_file.close()
    packaging_path = re.search('.*\/(centreon-plugin-.*)\/pkg.json', filepath).group(1)

    if not packaging_path == packaging["pkg_name"]:
        packaging_path = packaging_path + "=>" + packaging["pkg_name"]

    directory_path = re.search('^(.+)\/pkg.json', filepath).group(1)

    if 'packaging/centreon-plugin-Cloud-Azure-Network-TrafficManager' == directory_path:
        print('superrrrrrr')
        print(*packages)
        if 'packaging/centreon-plugin-Cloud-Azure-Network-TrafficManager' in packages:
            print('okkkkkkk')

    if directory_path in packages:
        print('wonderful ' + directory_path)
    #print(directory_path)
    if common:
        list_packages.add(packaging_path)
    elif directory_path in packages:
        list_packages.add(packaging_path)
    elif ('packaging/' + packaging["pkg_name"]) in packages:
        list_packages.add(packaging_path)
    else:
        for pkg_file in packaging["files"]:
            pkg_file_dir = pkg_file.strip('/').removeprefix('centreon-plugins/')
            if pkg_file_dir in list_plugins:
                list_packages.add(packaging_path)

print(*list_packages)
