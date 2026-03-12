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

package network::westermo::standard::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
            key_values      => [ { name => 'average_1m' } ],
            output_template => '%.2f %% (1m)',
            perfdatas       => [
                { label => 'cpu_1m_avg', value => 'average_1m', template => '%.2f',
                    min => 0, max => 100, unit => '%' },
            ],
        }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
            key_values      => [ { name => 'average_5m' } ],
            output_template => '%.2f %% (5m)',
            perfdatas       => [
                { label => 'cpu_5m_avg', value => 'average_5m', template => '%.2f',
                    min => 0, max => 100, unit => '%' },
            ],
        }
        },
        { label => 'average-15m', nlabel => 'cpu.utilization.15m.percentage', set => {
            key_values      => [ { name => 'average_15m' } ],
            output_template => '%.2f %% (15m)',
            perfdatas       => [
                { label => 'cpu_15m_avg', value => 'average_15m', template => '%.2f',
                    min => 0, max => 100, unit => '%' },
            ],
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_cpuLoadAvg1Min = '.1.3.6.1.4.1.16177.2.1.5.3.2.1.0';
    my $oid_cpuLoadAvg5Min = '.1.3.6.1.4.1.16177.2.1.5.3.2.2.0';
    my $oid_cpuLoadAvg15Min = '.1.3.6.1.4.1.16177.2.1.5.3.2.3.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [ $oid_cpuLoadAvg1Min, $oid_cpuLoadAvg5Min, $oid_cpuLoadAvg15Min ],
        nothing_quit => 1
    );

    $self->{global} = {
        average_1m => $snmp_result->{$oid_cpuLoadAvg1Min},
        average_5m => $snmp_result->{$oid_cpuLoadAvg5Min},
        average_1m => $snmp_result->{$oid_cpuLoadAvg15Min},
    };
}

1;

__END__

=head1 MODE

Check average cpu load.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='average-15m'>

=item B<--warning-*>

Warning threshold.

Can be: 'average-1m', 'average-5m', 'average-15m'

=item B<--critical-*>

Critical threshold.

Can be: 'average-1m', 'average-5m', 'average-15m'

=back

=cut
