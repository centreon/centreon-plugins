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

package network::raisecom::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance} . "' usage ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usage for every period are OK.', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => '1s', nlabel => 'cpu.utilization.1s.percentage', set => {
                key_values => [ { name => 'oneSec' } ],
                output_template => '%.2f%% (1sec)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => '5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'fiveSec' } ],
                output_template => '%.2f%% (5sec)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => '1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'oneMin' } ],
                output_template => '%.2f%% (1min)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => '10m', nlabel => 'cpu.utilization.10m.percentage', set => {
                key_values => [ { name => 'tenMin' } ],
                output_template => '%.2f%% (10min)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => '2h', nlabel => 'cpu.utilization.2h.percentage', set => {
                key_values => [ { name => 'twoHour' } ],
                output_template => '%.2f%% (2h)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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

my %mapping_period = (1 => 'oneSec', 2 => 'fiveSec', 3 => 'oneMin', 4 => 'tenMin', 5 => 'twoHour');

my $mapping = {
    raisecomCPUUtilizationPeriod    => { oid => '.1.3.6.1.4.1.8886.1.1.1.5.1.1.1.2', map => \%mapping_period },
    raisecomCPUUtilization          => { oid => '.1.3.6.1.4.1.8886.1.1.1.5.1.1.1.3' }
};
my $mapping_pon = {
    rcCpuUsage1Second    => { oid => '.1.3.6.1.4.1.8886.18.1.7.1.1.1.3' },
    rcCpuUsage10Minutes  => { oid => '.1.3.6.1.4.1.8886.18.1.7.1.1.1.4' },
    rcCpuUsage2Hours     => { oid => '.1.3.6.1.4.1.8886.18.1.7.1.1.1.5' }
};

my $oid_raisecomCPUUtilizationEntry = '.1.3.6.1.4.1.8886.1.1.1.5.1.1.1';
my $oid_pon_raisecomCPUUtilizationEntry = '.1.3.6.1.4.1.8886.18.1.7.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(oid => $oid_raisecomCPUUtilizationEntry, nothing_quit => 0);

    $self->{cpu} = {};
    if (scalar(keys %{$snmp_result}) <= 0) {
        my $result = $options{snmp}->get_table(oid => $oid_pon_raisecomCPUUtilizationEntry, nothing_quit => 1);
        foreach my $oid (keys %{$result}) {
            next if ($oid !~ /^$mapping_pon->{rcCpuUsage1Second}->{oid}\.(.*)\.(.*)$/);
            my $instance = $1;
            my $mapping_result = $options{snmp}->map_instance(mapping => $mapping_pon, results => $result, instance => $instance . '.' . 0);
            $self->{cpu}->{$instance} = {
                oneSec  => $mapping_result->{rcCpuUsage1Second},
                tenMin  => $mapping_result->{rcCpuUsage10Minutes},
                twoHour => $mapping_result->{rcCpuUsage2Hours}
            };
        }
    } else {
        $self->{cpu} = { 0 => {} };

        foreach my $oid (keys %{$snmp_result}) {
            next if ($oid !~ /^$mapping->{raisecomCPUUtilization}->{oid}\.(.*)$/);
            my $instance = $1;
            my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

            $self->{cpu}->{0}->{ $result->{raisecomCPUUtilizationPeriod} } = $result->{raisecomCPUUtilization};
        }
    };
}

1;

__END__

=head1 MODE

Check CPU usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(1s|1m)$'

=item B<--warning-*>

Warning threshold.
Can be: '1s', '5s', '1m', '10m', '2h' for standard Raisecom devices.

Can be: '1s', '10m', '2h' for xPON Raisecom devices.

=item B<--critical-*>

Critical threshold.
Can be: '1s', '5s', '1m', '10m', '2h'.

Can be: '1s', '10m', '2h' for xPON Raisecom devices.

=back

=cut
