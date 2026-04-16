#!/usr/bin/env python3

import json
from sys import argv

package_path = argv[1]
package_name = argv[2]
package_version = argv[3]
package_release = argv[4]

with open('.github/packaging/rpm/plugin.spectemplate', 'r') as rfile:
    specfile = rfile.read()

with open('packaging/%s/pkg.json' % package_path, 'r') as rfile:
    plugincfg = json.load(rfile)

with open('packaging/%s/rpm.json' % package_path, 'r') as rfile:
    pluginrpm = json.load(rfile)

specfile = specfile.replace('@NAME@', package_name)
specfile = specfile.replace('@VERSION@', package_version)
specfile = specfile.replace('@RELEASE@', package_release)
specfile = specfile.replace('@SUMMARY@', plugincfg['pkg_summary'])
specfile = specfile.replace('@PLUGIN_NAME@', plugincfg['plugin_name'])
specfile = specfile.replace(
    '@REQUIRES@',
    "\n".join(["Requires:\t%s" % x for x in pluginrpm.get('dependencies', '')])
)
specfile = specfile.replace(
    '@CUSTOM_PKG_DATA@', pluginrpm.get('custom_pkg_data', '')
)

# write final specfile
with open('plugin.specfile', 'w+') as wfile:
    wfile.write(specfile)