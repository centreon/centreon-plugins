#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
                    { label => 'total_cpu_5s_avg', value => 'average_5s_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'average-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { label => 'total_cpu_1m_avg', value => 'average_1m_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'average-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { label => 'total_cpu_5m_avg', value => 'average_5m_absolute', template => '%.2f',
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
                    { label => 'cpu_5s', value => 'cpu_5s_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'core-1m', nlabel => 'core.cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' }, { name => 'display' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { label => 'cpu_1m', value => 'cpu_1m_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'core-5m', nlabel => 'core.cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_5m' }, { name => 'display' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { label => 'cpu_5m', value => 'cpu_5m_absolute', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display_absolute' },
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
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_nexus_cpu {
    my ($self, %options) = @_;
    
    if (!defined($self->{results}->{$options{oid}}->{$options{oid} . '.0'})) {
        return 0;
    }

    my $instance = 0;
    $self->{cpu_core}->{$instance} = {
        display => $instance,
        cpu_5m => $self->{results}->{$options{oid}}->{$options{oid} . '.0'},
    };

    return 1;
}

sub check_table_cpu {
    my ($self, %options) = @_;
    
    my $checked = 0;
    my $instances =  {};
    foreach my $oid (keys %{$self->{results}->{$options{entry}}}) {
        $oid =~ /\.([0-9]+)$/;
        next if (defined($instances->{$1}));
        $instances->{$1} = 1;        
        my $instance = $1;
        
        my $cpu5sec = defined($self->{results}->{$options{entry}}->{$options{sec5} . '.' . $instance}) ? $self->{results}->{$options{entry}}->{$options{sec5} . '.' . $instance}  : undef;
        my $cpu1min = defined($self->{results}->{$options{entry}}->{$options{min1} . '.' . $instance}) ? $self->{results}->{$options{entry}}->{$options{min1} . '.' . $instance} : undef;
        my $cpu5min = defined($self->{results}->{$options{entry}}->{$options{min5} . '.' . $instance}) ? $self->{results}->{$options{entry}}->{$options{min5} . '.' . $instance} : undef;
        
        # Case that it's maybe other CPU oid in table for datas.
        next if (!defined($cpu5sec) && !defined($cpu1min) && !defined($cpu5min));

        $checked = 1;
        $self->{cpu_core}->{$instance} = {
            display => $instance,
            cpu_5s => $cpu5sec,
            cpu_1m => $cpu1min,
            cpu_5m => $cpu5min,
        };
    }
    
    return $checked;
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

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};

    # Cisco IOS Software releases later to 12.0(3)T and prior to 12.2(3.5)
    my $oid_cpmCPUTotalEntry = '.1.3.6.1.4.1.9.9.109.1.1.1.1';
    my $oid_cpmCPUTotal5sec = '.1.3.6.1.4.1.9.9.109.1.1.1.1.3';
    my $oid_cpmCPUTotal1min = '.1.3.6.1.4.1.9.9.109.1.1.1.1.4';
    my $oid_cpmCPUTotal5min = '.1.3.6.1.4.1.9.9.109.1.1.1.1.5';
    # Cisco IOS Software releases 12.2(3.5) or later
    my $oid_cpmCPUTotal5minRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.8';
    my $oid_cpmCPUTotal1minRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.7';
    my $oid_cpmCPUTotal5secRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.6';
    # Cisco IOS Software releases prior to 12.0(3)T
    my $oid_lcpu = '.1.3.6.1.4.1.9.2.1';
    my $oid_busyPer = '.1.3.6.1.4.1.9.2.1.56'; # .0 in reality
    my $oid_avgBusy1 = '.1.3.6.1.4.1.9.2.1.57'; # .0 in reality
    my $oid_avgBusy5 = '.1.3.6.1.4.1.9.2.1.58'; # .0 in reality
    # Cisco Nexus
    my $oid_cseSysCPUUtilization = '.1.3.6.1.4.1.9.9.305.1.1.1'; # .0 in reality
    
    $self->{results} = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cpmCPUTotalEntry, start => $oid_cpmCPUTotal5sec, end => $oid_cpmCPUTotal5minRev },
            { oid => $oid_lcpu, start => $oid_busyPer, end => $oid_avgBusy5 },
            { oid => $oid_cseSysCPUUtilization },
        ],
        nothing_quit => 1
    );
    
    if (!$self->check_table_cpu(entry => $oid_cpmCPUTotalEntry, sec5 => $oid_cpmCPUTotal5secRev, min1 => $oid_cpmCPUTotal1minRev, min5 => $oid_cpmCPUTotal5minRev)
        && !$self->check_table_cpu(entry => $oid_cpmCPUTotalEntry, sec5 => $oid_cpmCPUTotal5sec, min1 => $oid_cpmCPUTotal1min, min5 => $oid_cpmCPUTotal5min)
        && !$self->check_table_cpu(entry => $oid_lcpu, sec5 => $oid_busyPer, min1 => $oid_avgBusy1, min5 => $oid_avgBusy5)
       ) {
        if (!$self->check_nexus_cpu(oid => $oid_cseSysCPUUtilization)) {
            $self->{output}->add_option_msg(short_msg => "Cannot find CPU informations");
            $self->{output}->option_exit();
        }
    }

    $self->check_cpu_average();
}

1;

__END__

=head1 MODE

Check cpu usage (CISCO-PROCESS-MIB and CISCO-SYSTEM-EXT-MIB).

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core-5s', 'core-1m', 'core-5m', 'average-5s', 'average-1m', 'average-5m'.

=back

=cut
