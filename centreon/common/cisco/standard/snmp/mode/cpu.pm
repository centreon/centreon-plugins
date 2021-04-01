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

package centreon::common::cisco::standard::snmp::mode::cpu;

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
                    { label => 'total_cpu_5s_avg', value => 'average_5s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { label => 'total_cpu_1m_avg', value => 'average_1m', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { label => 'total_cpu_5m_avg', value => 'average_5m', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core-5s', nlabel => 'core.cpu.utilization.5s.percentage', set => {
                key_values => [ { name => 'cpu_5s' }, { name => 'display' } ],
                output_template => '%.2f %% (5s)',
                perfdatas => [
                    { label => 'cpu_5s', value => 'cpu_5s', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'core-1m', nlabel => 'core.cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' }, { name => 'display' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { label => 'cpu_1m', value => 'cpu_1m', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'core-5m', nlabel => 'core.cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_5m' }, { name => 'display' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { label => 'cpu_5m', value => 'cpu_5m', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'check-order:s'     => { name => 'check_order', default => 'process,old_sys,system_ext' },
    });

    return $self;
}

sub check_nexus_cpu {
    my ($self, %options) = @_;
    
    return if (!defined($options{snmp_result}->{$options{oid} . '.0'}));

    my $instance = 0;
    $self->{cpu_core}->{$instance} = {
        display => $instance,
        cpu_5m => $options{snmp_result}->{$options{oid} . '.0'},
    };

    $self->{checked_cpu} = 1;
}

sub check_table_cpu {
    my ($self, %options) = @_;
    
    return if ($self->{checked_cpu} == 1);

    my $instances =  {};
    foreach my $oid (keys %{$options{snmp_result}}) {
        $oid =~ /\.([0-9]+)$/;
        next if (defined($instances->{$1}));
        $instances->{$1} = 1;        
        my $instance = $1;
        
        my $cpu5sec = defined($options{snmp_result}->{$options{sec5} . '.' . $instance}) ? $options{snmp_result}->{$options{sec5} . '.' . $instance}  : undef;
        my $cpu1min = defined($options{snmp_result}->{$options{min1} . '.' . $instance}) ? $options{snmp_result}->{$options{min1} . '.' . $instance} : undef;
        my $cpu5min = defined($options{snmp_result}->{$options{min5} . '.' . $instance}) ? $options{snmp_result}->{$options{min5} . '.' . $instance} : undef;

        # Case that it's maybe other CPU oid in table for datas.
        next if (!defined($cpu5sec) && !defined($cpu1min) && !defined($cpu5min));

        $self->{checked_cpu} = 1;
        $self->{cpu_core}->{$instance} = {
            display => $instance,
            cpu_5s => $cpu5sec,
            cpu_1m => $cpu1min,
            cpu_5m => $cpu5min,
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

sub check_cpu_process {
    my ($self, %options) = @_;

    return if ($self->{checked_cpu} == 1);

    # Cisco IOS Software releases later to 12.0(3)T and prior to 12.2(3.5)
    my $oid_cpmCPUTotalEntry = '.1.3.6.1.4.1.9.9.109.1.1.1.1';
    my $oid_cpmCPUTotal5sec = '.1.3.6.1.4.1.9.9.109.1.1.1.1.3';
    my $oid_cpmCPUTotal1min = '.1.3.6.1.4.1.9.9.109.1.1.1.1.4';
    my $oid_cpmCPUTotal5min = '.1.3.6.1.4.1.9.9.109.1.1.1.1.5';
    # Cisco IOS Software releases 12.2(3.5) or later
    my $oid_cpmCPUTotal5minRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.8';
    my $oid_cpmCPUTotal1minRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.7';
    my $oid_cpmCPUTotal5secRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.6';

    my $snmp_result = $self->{snmp}->get_table(
        oid => $oid_cpmCPUTotalEntry, start => $oid_cpmCPUTotal5sec, end => $oid_cpmCPUTotal5minRev
    );
    $self->check_table_cpu(snmp_result => $snmp_result, sec5 => $oid_cpmCPUTotal5secRev, min1 => $oid_cpmCPUTotal1minRev, min5 => $oid_cpmCPUTotal5minRev);
    $self->check_table_cpu(snmp_result => $snmp_result, sec5 => $oid_cpmCPUTotal5sec, min1 => $oid_cpmCPUTotal1min, min5 => $oid_cpmCPUTotal5min);
}

sub check_cpu_old_sys {
    my ($self, %options) = @_;

    return if ($self->{checked_cpu} == 1);

    # Cisco IOS Software releases prior to 12.0(3)T
    my $oid_lcpu = '.1.3.6.1.4.1.9.2.1';
    my $oid_busyPer = '.1.3.6.1.4.1.9.2.1.56'; # .0 in reality
    my $oid_avgBusy1 = '.1.3.6.1.4.1.9.2.1.57'; # .0 in reality
    my $oid_avgBusy5 = '.1.3.6.1.4.1.9.2.1.58'; # .0 in reality
    
    my $snmp_result = $self->{snmp}->get_table(
        oid => $oid_lcpu, start => $oid_busyPer, end => $oid_avgBusy5
    );
    $self->check_table_cpu(snmp_result => $snmp_result, sec5 => $oid_busyPer, min1 => $oid_avgBusy1, min5 => $oid_avgBusy5);
}

sub check_cpu_system_ext {
    my ($self, %options) = @_;

    return if ($self->{checked_cpu} == 1);

    # Cisco Nexus
    my $oid_cseSysCPUUtilization = '.1.3.6.1.4.1.9.9.305.1.1.1'; # .0 in reality
    my $snmp_result = $self->{snmp}->get_table(
        oid => $oid_cseSysCPUUtilization
    );

    $self->check_nexus_cpu(snmp_result => $snmp_result, oid => $oid_cseSysCPUUtilization);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};
    $self->{checked_cpu} = 0;
    
    foreach (split /,/, $self->{option_results}->{check_order}) {
        my $method = $self->can('check_cpu_' . $_);
        if ($method) {
            $self->$method();
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

Check cpu usage (CISCO-PROCESS-MIB and CISCO-SYSTEM-EXT-MIB).

=over 8

=item B<--check-order>

Check cpu in standard cisco mib. If you have some issue (wrong cpu information in a specific mib), you can change the order 
(Default: 'process,old_sys,system_ext').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core-5s', 'core-1m', 'core-5m', 'average-5s', 'average-1m', 'average-5m'.

=back

=cut
