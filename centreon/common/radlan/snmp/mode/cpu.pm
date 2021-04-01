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

package centreon::common::radlan::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 0, cb_prefix_output => 'prefix_message_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'average-1s', nlabel => 'cpu.utilization.1s.percentage', set => {
                key_values => [ { name => 'average_1s' } ],
                output_template => '%.2f %% (1s)',
                perfdatas => [
                    { value => 'average_1s', template => '%.2f',
                      min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { value => 'average_1m', template => '%.2f',
                      min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { value => 'average_5m', template => '%.2f',
                      min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub prefix_message_output {
    my ($self, %options) = @_;

    return "CPU average usage: ";
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

    my $oid_rlCpuUtilDuringLastSecond = '.1.3.6.1.4.1.89.1.7.0';
    my $oid_rlCpuUtilDuringLastMinute = '.1.3.6.1.4.1.89.1.8.0';
    my $oid_rlCpuUtilDuringLast5Minutes = '.1.3.6.1.4.1.89.1.9.0';
    my $result = $options{snmp}->get_leef(
        oids => [$oid_rlCpuUtilDuringLastSecond, $oid_rlCpuUtilDuringLastMinute, $oid_rlCpuUtilDuringLast5Minutes],
        nothing_quit => 1
    );

    $self->{cpu} = {
        average_1s => $result->{$oid_rlCpuUtilDuringLastSecond},
        average_1m => $result->{$oid_rlCpuUtilDuringLastMinute},
        average_5m => $result->{$oid_rlCpuUtilDuringLast5Minutes}
    }
}



1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'average-1s' (%), 'average-1m' (%), 'average-5m' (%).

=back

=cut
