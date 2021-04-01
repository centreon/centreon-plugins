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

package centreon::common::foundry::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'utilization-5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'cpu_5s' }, { name => 'display' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { value => 'cpu_5s',  template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'utilization-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' }, { name => 'display' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { value => 'cpu_1m',  template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'utilization-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_5m' }, { name => 'display' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { value => 'cpu_5m',  template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' usage: ";
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

    my $oid_snAgentCpuUtilPercent = '.1.3.6.1.4.1.1991.1.1.2.11.1.1.5';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_snAgentCpuUtilPercent, nothing_quit => 1);

    $self->{cpu} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_snAgentCpuUtilPercent\.(.*?)\.(.*?)\.60/);
        my $instance = "slot$1:cpu$2";

        $self->{cpu}->{$instance} = {
            display => $instance,
            cpu_5s => $snmp_result->{ $oid_snAgentCpuUtilPercent . '.' . $1 . '.' . $2 . '.5' },
            cpu_1m => $snmp_result->{ $oid_snAgentCpuUtilPercent . '.' . $1 . '.' . $2 . '.60' },
            cpu_5m => $snmp_result->{ $oid_snAgentCpuUtilPercent . '.' . $1 . '.' . $2 . '.300' }
        };
    }
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'utilization-5s', 'utilization-1m', 'utilization-5m'.

=back

=cut
