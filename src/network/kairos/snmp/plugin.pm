#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::kairos::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'alarms'          => 'network::kairos::snmp::mode::alarms',
        'cpu'             => 'snmp_standard::mode::cpu',
        'cpu-detailed'    => 'snmp_standard::mode::cpudetailed',
        'hardware'        => 'network::kairos::snmp::mode::hardware',
        'interfaces'      => 'snmp_standard::mode::interfaces',
        'list-alarms'     => 'network::kairos::snmp::mode::listalarms',
        'list-interfaces' => 'snmp_standard::mode::listinterfaces',
        'load'            => 'snmp_standard::mode::loadaverage',
        'memory'          => 'snmp_standard::mode::memory',
        'uptime'          => 'snmp_standard::mode::uptime'
    };

    $self->{modes_options} = {
        'cpu'             => { force_new_perfdata => 1 },
        'cpudetailed'     => { force_new_perfdata => 1 },
        'interfaces'      => { force_new_perfdata => 1 },
        'load'            => { force_new_perfdata => 1 },
        'memory'          => { force_new_perfdata => 1 },
        'uptime'          => { force_new_perfdata => 1 }
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Kairos equipment in SNMP.

=cut
