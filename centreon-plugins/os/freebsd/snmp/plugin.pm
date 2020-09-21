#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package os::freebsd::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'cpu'              => 'snmp_standard::mode::cpu',
        'cpu-detailed'     => 'snmp_standard::mode::cpudetailed',
        'diskio'           => 'snmp_standard::mode::diskio',
        'disk-usage'       => 'snmp_standard::mode::diskusage',
        'inodes'           => 'snmp_standard::mode::inodes',
        'interfaces'       => 'snmp_standard::mode::interfaces',
        'load'             => 'snmp_standard::mode::loadaverage',
        'list-diskspath'   => 'snmp_standard::mode::listdiskspath',
        'list-interfaces'  => 'snmp_standard::mode::listinterfaces',
        'list-processes'   => 'snmp_standard::mode::listprocesses',
        'list-storages'    => 'snmp_standard::mode::liststorages',
        'memory'           => 'os::freebsd::snmp::mode::memory',
        'processcount'     => 'snmp_standard::mode::processcount',
        'storage'          => 'snmp_standard::mode::storage',
        'swap'             => 'snmp_standard::mode::swap',
        'time'             => 'snmp_standard::mode::ntp',
        'tcpcon'           => 'snmp_standard::mode::tcpcon',
        'uptime'           => 'snmp_standard::mode::uptime'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Freebsd operating systems in SNMP.
Some modes ('cpu', 'load, 'swap', 'memory') needs 'bsnmp-ucd'.

=cut
