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

package network::sonus::sbc::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'call-statistics'   => 'network::sonus::sbc::snmp::mode::callstats',
        'channels'          => 'network::sonus::sbc::snmp::mode::channels',
        'cpu'               => 'network::sonus::sbc::snmp::mode::cpu',
        'cpu-detailed'      => 'network::sonus::sbc::snmp::mode::cpudetailed',
        'dsp-stats'         => 'network::sonus::sbc::snmp::mode::dspstats',
        'interfaces'        => 'network::sonus::sbc::snmp::mode::interfaces',
        'list-interfaces'   => 'snmp_standard::mode::listinterfaces',
        'load'              => 'network::sonus::sbc::snmp::mode::load',
        'memory'            => 'network::sonus::sbc::snmp::mode::memory',
        'storage'           => 'network::sonus::sbc::snmp::mode::storage',
        'swap'              => 'network::sonus::sbc::snmp::mode::swap'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Sonus Session Border Controllers equipment in SNMP.

=cut
