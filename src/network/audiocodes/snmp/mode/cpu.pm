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

package network::audiocodes::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU(s) average usages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'voip', nlabel => 'cpu.voip.utilization.percentage', set => {
                key_values => [ { name => 'voip' } ],
                output_template => 'CPU VoIp usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'data', nlabel => 'cpu.data.utilization.percentage', set => {
                key_values => [ { name => 'data' } ],
                output_template => 'CPU data usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'core-cpu-utilization', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' } ],
                output_template => 'average usage is: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_acSysStateVoIpCpuUtilization = '.1.3.6.1.4.1.5003.9.10.10.2.5.10.0';
    my $oid_acSysStateDataCpuUtilization = '.1.3.6.1.4.1.5003.9.10.10.2.5.8.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_acSysStateVoIpCpuUtilization, $oid_acSysStateDataCpuUtilization],
        nothing_quit => 1
    );

    $self->{global} = { data => $snmp_result->{$oid_acSysStateDataCpuUtilization}, voip => $snmp_result->{$oid_acSysStateVoIpCpuUtilization} };

    my $oid_acKpiCpuStatsCurrentCpuCpuUtilization = '.1.3.6.1.4.1.5003.15.2.4.1.2.1.1.2';
    $snmp_result = $options{snmp}->get_table(oid => $oid_acKpiCpuStatsCurrentCpuCpuUtilization);

    $self->{cpu} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        $self->{cpu}->{$1} = { cpu_usage => $snmp_result->{$_} };
    }
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^voip$'

=item B<--warning-*> B<--critical-*>

Threshold.
Can be: 'voip', 'data', 'core-cpu-utilization'.

=back

=cut
