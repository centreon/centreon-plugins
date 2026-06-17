#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::xmlapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'audit-logs'          => 'hardware::server::cisco::ucs::xmlapi::mode::auditlogs',
        'equipment'           => 'hardware::server::cisco::ucs::xmlapi::mode::equipment',
        'fabric-interconnect' => 'hardware::server::cisco::ucs::xmlapi::mode::fabricinterconnect',
        'firmware'            => 'hardware::server::cisco::ucs::xmlapi::mode::firmware',
        'faults'              => 'hardware::server::cisco::ucs::xmlapi::mode::faults',
        'mgmt-entities'       => 'hardware::server::cisco::ucs::xmlapi::mode::mgmtentities',
        'ports'               => 'hardware::server::cisco::ucs::xmlapi::mode::ports',
        'service-profile'     => 'hardware::server::cisco::ucs::xmlapi::mode::serviceprofile',
        'vhba'                => 'hardware::server::cisco::ucs::xmlapi::mode::vhba',
    };

    $self->{custom_modes}->{xmlapi} = 'hardware::server::cisco::ucs::xmlapi::custom::xmlapi';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Cisco UCS via UCSM XML API (HTTPS POST to /nuova).

Available modes:
  equipment           - Hardware components: blade, chassis, fan, psu, cpu, memory,
                        localdisk, fex, iocard, temperature (use --component to filter)
  fabric-interconnect - Fabric Interconnect status and HA role
  firmware            - Firmware versions across all components
  faults              - Active system faults
  audit-logs          - UCSM audit log events
  mgmt-entities       - UCSM HA management entities
  ports               - Ethernet port status on Fabric Interconnects
  service-profile     - Service profile association status
  vhba                - Virtual HBA and physical FC port status

=cut
