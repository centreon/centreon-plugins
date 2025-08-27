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
        { label => 'cpu-load-1min', nlabel => 'cpu.load.1m.percentage', set => {
            key_values      => [ { name => 'cpu_load1' } ],
            output_template => '1min load average: %s%%',
            perfdatas       => [
                { label => 'cpu_load1', value => 'cpu_load1', template => '%s', min => 0 },
            ],
        }
        },
        { label => 'cpu-load-5min', nlabel => 'cpu.load.5m.percentage', set => {
            key_values      => [ { name => 'cpu_load5' } ],
            output_template => '5min load average: %s%%',
            perfdatas       => [
                { label => 'cpu_load5', value => 'cpu_load5', template => '%s', min => 0 },
            ],
        }
        },
        { label => 'cpu-load-15min', nlabel => 'cpu.load.15m.percentage', set => {
            key_values      => [ { name => 'cpu_load15' } ],
            output_template => '15min load average: %s%%',
            perfdatas       => [
                { label => 'cpu_load15', value => 'cpu_load15', template => '%s', min => 0 },
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
        cpu_load1  => $snmp_result->{$oid_cpuLoadAvg1Min},
        cpu_load5  => $snmp_result->{$oid_cpuLoadAvg5Min},
        cpu_load15 => $snmp_result->{$oid_cpuLoadAvg15Min},
    };
}

1;

__END__

=head1 MODE

Check average cpu load.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='cpu-load-15min'>

=item B<--warning-cpu-load-1min>

Warning thresholds for CPU load for C<1min> (in %).

=item B<--critical-cpu-load-1min>

Critical thresholds for CPU load for C<1min> (in %).

=item B<--warning-cpu-load-5min>

Warning thresholds for CPU load for C<5min> (in %).

=item B<--critical-cpu-load-5min>

Critical thresholds for CPU load for C<5min> (in %).

=item B<--warning-cpu-load-15min>

Warning thresholds for CPU load for C<15min> (in %).

=item B<--critical-cpu-load-15min>

Critical thresholds for CPU load for C<15min> (in %).

=back

=cut
