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

package network::audiocodes::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Memory ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'voip', nlabel => 'memory.voip.usage.percentage', set => {
                key_values => [ { name => 'voip' } ],
                output_template => 'VoIp usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'data', nlabel => 'memory.data.usage.percentage', set => {
                key_values => [ { name => 'data' } ],
                output_template => 'data usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'system', nlabel => 'memory.system.usage.percentage', set => {
                key_values => [ { name => 'system' } ],
                output_template => 'system usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_acSysStateVoIpMemoryUtilization = '.1.3.6.1.4.1.5003.9.10.10.2.5.11.0';
    my $oid_acSysStateDataMemoryUtilization = '.1.3.6.1.4.1.5003.9.10.10.2.5.9.0';
    my $oid_acKpiSystemStatsCurrentGlobalMemoryUtilization = '.1.3.6.1.4.1.5003.15.2.2.1.1.1.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_acSysStateVoIpMemoryUtilization, $oid_acSysStateDataMemoryUtilization, $oid_acKpiSystemStatsCurrentGlobalMemoryUtilization],
        nothing_quit => 1
    );

    $self->{global} = {
        data => $snmp_result->{$oid_acSysStateDataMemoryUtilization},
        voip => $snmp_result->{$oid_acSysStateVoIpMemoryUtilization},
        system => $snmp_result->{$oid_acKpiSystemStatsCurrentGlobalMemoryUtilization}
    };
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^voip$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'voip', 'data', 'system'.

=back

=cut
