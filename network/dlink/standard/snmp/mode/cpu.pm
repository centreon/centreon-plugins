#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::dlink::standard::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output', message_separator => ' ', skipped_code => { -10 => 1 } },
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_core_output', message_separator => ' ', message_multiple => 'All core cpu are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average-5s', nlabel => 'cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'average_5s' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core-5s', nlabel => 'core.cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'cpu_5s' }, { name => 'display' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'core-1m', nlabel => 'core.cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' }, { name => 'display' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'core-5m', nlabel => 'core.cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_5m' }, { name => 'display' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return $self->{cpu_avg}->{count} . " CPU(s) average usage is ";
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' usage ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'check-order:s' => { name => 'check_order', default => 'common,industrial,agent' },
    });

    return $self;
}

sub check_table_cpu {
    my ($self, %options) = @_;

    my $instances =  {};
    foreach my $oid (keys %{$options{snmp_result}}) {
        $oid =~ /\.(\d+)\.(\d+)$/;
        my $display = 'unit' . $1 . $self->{output}->get_instance_perfdata_separator() . $2;
        my $instance = $1 . '.' . $2;
        next if (defined($instances->{$instance}));
        $instances->{$instance} = 1;

        my $cpu5sec = defined($options{snmp_result}->{$options{sec5} . '.' . $instance}) ? $options{snmp_result}->{$options{sec5} . '.' . $instance}  : undef;
        my $cpu1min = defined($options{snmp_result}->{$options{min1} . '.' . $instance}) ? $options{snmp_result}->{$options{min1} . '.' . $instance} : undef;
        my $cpu5min = defined($options{snmp_result}->{$options{min5} . '.' . $instance}) ? $options{snmp_result}->{$options{min5} . '.' . $instance} : undef;

        # Case that it's maybe other CPU oid in table for datas.
        next if (!defined($cpu5sec) && !defined($cpu1min) && !defined($cpu5min));

        $self->{checked_cpu} = 1;
        $self->{cpu_core}->{$instance} = {
            display => $display,
            cpu_5s => $cpu5sec,
            cpu_1m => $cpu1min,
            cpu_5m => $cpu5min
        };
    }    
}

sub check_cpu_average {
    my ($self, %options) = @_;

    my $count = scalar(keys %{$self->{cpu_core}});
    my ($avg_5s, $avg_1m, $avg_5m);
    foreach (values %{$self->{cpu_core}}) {
        $avg_5s = defined($avg_5s) ? $avg_5s + $_->{cpu_5s} : $_->{cpu_5s}
            if (defined($_->{cpu_5s}));
        $avg_1m = defined($avg_1m) ? $avg_1m + $_->{cpu_1m} : $_->{cpu_1m}
            if (defined($_->{cpu_1m}));
        $avg_5m = defined($avg_5m) ? $avg_5m + $_->{cpu_5m} : $_->{cpu_5m}
            if (defined($_->{cpu_5m}));
    }
    
    $self->{cpu_avg} = {
        average_5s => defined($avg_5s) ? $avg_5s / $count : undef,
        average_1m => defined($avg_1m) ? $avg_1m / $count : undef,
        average_5m => defined($avg_5m) ? $avg_5m / $count : undef,
        count => $count,
    };
}

sub check_cpu_industrial {
    my ($self, %options) = @_;

    return if ($self->{checked_cpu} == 1);

    my $oid_dEntityExtCpuUtilEntry = '.1.3.6.1.4.1.171.14.5.1.7.1';
    my $oid_dEntityExtCpuUtilFiveSeconds = '.1.3.6.1.4.1.171.14.5.1.7.1.3';
    my $oid_dEntityExtCpuUtilOneMinute = '.1.3.6.1.4.1.171.14.5.1.7.1.4';
    my $oid_dEntityExtCpuUtilFiveMinutes = '.1.3.6.1.4.1.171.14.5.1.7.1.5';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_dEntityExtCpuUtilEntry, start => $oid_dEntityExtCpuUtilFiveSeconds, end => $oid_dEntityExtCpuUtilFiveMinutes
    );
    $self->check_table_cpu(
        snmp_result => $snmp_result,
        sec5 => $oid_dEntityExtCpuUtilFiveSeconds,
        min1 => $oid_dEntityExtCpuUtilOneMinute,
        min5 => $oid_dEntityExtCpuUtilFiveMinutes
    );
}

sub check_cpu_agent {
    my ($self, %options) = @_;

    return if ($self->{checked_cpu} == 1);

    my $oid_agentCPUutilizationIn5sec = '.1.3.6.1.4.1.171.12.1.1.6.1.0';
    my $oid_agentCPUutilizationIn1min = '.1.3.6.1.4.1.171.12.1.1.6.2.0';
    my $oid_agentCPUutilizationIn5min = '.1.3.6.1.4.1.171.12.1.1.6.3.0';
    
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_agentCPUutilizationIn5sec, $oid_agentCPUutilizationIn1min, $oid_agentCPUutilizationIn5min]
    );

    if (defined($snmp_result->{$oid_agentCPUutilizationIn5min})) {
        $self->{checked_cpu} = 1;         
        $self->{cpu_core}->{0} = {
            display => 0,
            cpu_5s => $snmp_result->{$oid_agentCPUutilizationIn5sec},
            cpu_1m => $snmp_result->{$oid_agentCPUutilizationIn1min},
            cpu_5m => $snmp_result->{$oid_agentCPUutilizationIn5min}
        };
    }
}

sub check_cpu_common {
    my ($self, %options) = @_;

    return if ($self->{checked_cpu} == 1);

    my $oid_esEntityExtCpuUtilEntry = '.1.3.6.1.4.1.171.17.5.1.7.1';
    my $oid_esEntityExtCpuUtilFiveSeconds = '.1.3.6.1.4.1.171.17.5.1.7.1.3';
    my $oid_esEntityExtCpuUtilOneMinute = '.1.3.6.1.4.1.171.17.5.1.7.1.4';
    my $oid_esEntityExtCpuUtilFiveMinutes = '.1.3.6.1.4.1.171.17.5.1.7.1.5';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_esEntityExtCpuUtilEntry, start => $oid_esEntityExtCpuUtilFiveSeconds, end => $oid_esEntityExtCpuUtilFiveMinutes
    );
    $self->check_table_cpu(
        snmp_result => $snmp_result,
        sec5 => $oid_esEntityExtCpuUtilFiveSeconds,
        min1 => $oid_esEntityExtCpuUtilOneMinute,
        min5 => $oid_esEntityExtCpuUtilFiveMinutes
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};
    $self->{checked_cpu} = 0;
    
    foreach (split /,/, $self->{option_results}->{check_order}) {
        my $method = $self->can('check_cpu_' . $_);
        if ($method) {
            $self->$method(snmp => $options{snmp});
        }
    }

    if ($self->{checked_cpu} == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find CPU informations");
        $self->{output}->option_exit();
    }

    $self->check_cpu_average();
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--check-order>

Check cpu in standard dlink mib. If you have some issue (wrong cpu information in a specific mib), you can change the order 
(Default: 'common,industrial,agent').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core-5s', 'core-1m', 'core-5m', 'average-5s', 'average-1m', 'average-5m'.

=back

=cut
