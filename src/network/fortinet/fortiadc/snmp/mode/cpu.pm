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

package network::fortinet::fortiadc::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return $self->{cpu_avg}->{count} . " CPU(s) average usage is ";
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{core_id} . "' usage ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output', message_separator => ' ', skipped_code => { -10 => 1 } },
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_core_output', message_separator => ' ', message_multiple => 'All core cpu are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average-2s', nlabel => 'cpu.utilization.2s.percentage', set => {
                key_values => [ { name => 'average_2s' } ],
                output_template => '%.2f %% (2s)',
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
        { label => 'core-2s', nlabel => 'core.cpu.utilization.2s.percentage', set => {
                key_values => [ { name => 'cpu_2s' } ],
                output_template => '%.2f %% (2s)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'core-1m', nlabel => 'core.cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'core-5m', nlabel => 'core.cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_5m' } ],
                output_template => '%.2f %% (5m)',
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
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_cpu_average {
    my ($self, %options) = @_;

    my $count = scalar(keys %{$self->{cpu_core}});
    my ($avg_2s, $avg_1m, $avg_5m);
    foreach (values %{$self->{cpu_core}}) {
        $avg_2s = defined($avg_2s) ? $avg_2s + $_->{cpu_2s} : $_->{cpu_2s}
            if (defined($_->{cpu_2s}));
        $avg_1m = defined($avg_1m) ? $avg_1m + $_->{cpu_1m} : $_->{cpu_1m}
            if (defined($_->{cpu_1m}));
        $avg_5m = defined($avg_5m) ? $avg_5m + $_->{cpu_5m} : $_->{cpu_5m}
            if (defined($_->{cpu_5m}));
    }

    $self->{cpu_avg} = {
        average_2s => defined($avg_2s) ? $avg_2s / $count : undef,
        average_1m => defined($avg_1m) ? $avg_1m / $count : undef,
        average_5m => defined($avg_5m) ? $avg_5m / $count : undef,
        count => $count
    };
}

my $mapping = {
    name   => { oid => '.1.3.6.1.4.1.12356.112.1.40.1.2' }, # fadcCpuName
    cpu_2s => { oid => '.1.3.6.1.4.1.12356.112.1.40.1.3' }, # fadcCpu2secAvgUsage
    cpu_1m => { oid => '.1.3.6.1.4.1.12356.112.1.40.1.4' }, # fadcCpu1minAvgUsage
    cpu_5m => { oid => '.1.3.6.1.4.1.12356.112.1.40.1.5' }  # fadcCpu5minAvgUsage
};
my $oid_cpu_table = '.1.3.6.1.4.1.12356.112.1.40.1'; # fadcSysCpuUsageTable

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_cpu_table,
        nothing_quit => 1
    );

    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};    
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{cpu_5m}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{cpu_core}->{ $result->{name} } = { core_id => $instance, %$result };
    }

    $self->check_cpu_average();
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core-2s', 'core-1m', 'core-5m', 'average-2s', 'average-1m', 'average-5m'.

=back

=cut
