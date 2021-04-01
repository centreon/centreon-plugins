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

package network::allied::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_cpu_avg_output', message_separator => ' ', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { value => 'average_1m', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { value => 'average_5m', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return 'CPU(s) average usage is ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_cpuUtilisationAvgLast5Minutes = '.1.3.6.1.4.1.207.8.4.4.3.3.7.0';
    my $oid_cpuUtilisationAvgLastMinute = '.1.3.6.1.4.1.207.8.4.4.3.3.3.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_cpuUtilisationAvgLast5Minutes, $oid_cpuUtilisationAvgLastMinute
        ],
        nothing_quit => 1
    );

    $self->{global} = { 
        average_1m => $snmp_result->{$oid_cpuUtilisationAvgLastMinute},
        average_5m => $snmp_result->{$oid_cpuUtilisationAvgLast5Minutes}
    };
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'average-1m', 'average-5m'.

=back

=cut
