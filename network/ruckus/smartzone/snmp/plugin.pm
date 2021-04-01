#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package network::ruckus::smartzone::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.5';
    %{$self->{modes}} = (
        'access-points'      => 'network::ruckus::smartzone::snmp::mode::accesspoints',
        'cpu'                => 'snmp_standard::mode::cpu',
        'interfaces'         => 'snmp_standard::mode::interfaces',
        'list-access-points' => 'network::ruckus::smartzone::snmp::mode::listaccesspoints',
        'list-interfaces'    => 'snmp_standard::mode::listinterfaces',
        'list-storages'      => 'snmp_standard::mode::liststorages',
        'load'               => 'snmp_standard::mode::loadaverage',
        'memory'             => 'snmp_standard::mode::memory',
        'storage'            => 'snmp_standard::mode::storage',
        'system'             => 'network::ruckus::smartzone::snmp::mode::system',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Ruckus SmartZone in SNMP.

=cut
