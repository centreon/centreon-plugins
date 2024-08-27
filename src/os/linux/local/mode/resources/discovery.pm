#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package os::linux::local::mode::resources::discovery;

use strict;
use warnings;
use Exporter;

our $discovery_match;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($discovery_match);

$discovery_match = [
    { type => 'cisco asa', re => qr/Cisco Adaptative Security Appliance/i },
    { type => 'cisco standard', re => qr/Cisco IOS Software/i },
    { type => 'emc data domain', re => qr/Data Domain/i },
    { type => 'sonicwall', re => qr/SonicWALL/i },
    { type => 'silverpeak', re => qr/Silver Peak/i },
    { type => 'stonesoft', re => qr/Forcepoint/i },
    { type => 'redback', re => qr/Redback/i },
    { type => 'palo alto', re => qr/Palo Alto/i },
    { type => 'hp procurve', re => qr/HP.*Switch/i },
    { type => 'hp procurve', re => qr/HP ProCurve/i },
    { type => 'hp standard', re => qr/HPE Comware/i },
    { type => 'hp msl', re => qr/HP MSL/i },
    { type => 'mrv optiswitch', re => qr/OptiSwitch/i },
    { type => 'netapp', re => qr/Netapp/i },
    { type => 'linux', re => qr/linux/i },
    { type => 'windows', re => qr/windows/i },
    { type => 'macos', re => qr/Darwin/i },
    { type => 'hp-ux', re => qr/HP-UX/i },
    { type => 'freebsd', re => qr/FreeBSD/i },
    { type => 'aix', re => qr/ AIX / }
];

1;
