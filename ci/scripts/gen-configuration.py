#!/usr/bin/env python3

import json
import os
import re

PluginsPath = '/src/centreon-plugins/ci/debian/tools/packaging-plugins'

output = """Source: centreon-plugins
Section: net
Priority: optional
Maintainer: Luiz Costa <me@luizgustavo.pro.br>
Build-Depends: 
  debhelper-compat (= 12),
  libapp-fatpacker-perl,
  libfile-copy-recursive-perl,
  libjson-perl
Standards-Version: 4.5.0
Homepage: https://www.centreon.com


"""

for dir in next(os.walk(PluginsPath))[1]:
    print('Processing file %s/%s/pkg.json' % (PluginsPath, dir))
    with open('%s/%s/pkg.json' % (PluginsPath, dir), 'r') as pkgjson:
        pl_info = json.load(pkgjson)
    print('Processing file %s/%s/deb.json' % (PluginsPath, dir))
    with open('%s/%s/deb.json' % (PluginsPath, dir), 'r') as debjson:
        pl_deb = json.load(debjson)

    output += 'Package: %s\n' % pl_info['pkg_name'].lower()
    output += 'Architecture: any\n'
    output += 'Description: %s\n' % pl_info['pkg_summary']
    output += 'Depends:\n  ${shlibs:Depends},\n  ${misc:Depends},\n'
    output += re.sub(r'\n','\n  ', re.sub(r'^', '  ', ',\n'.join(pl_deb['dependencies'])))
    output += '\n\n'
    
    with open('/src/centreon-plugins/ci/debian/%s.install' % pl_info['pkg_name'].lower(), 'w+') as installFile:
        installFile.write('build/%s usr/lib/centreon/plugins\n' % pl_info['plugin_name'])

with open('/src/centreon-plugins/ci/debian/control', 'w+') as DebianControl:
    DebianControl.write(output)
