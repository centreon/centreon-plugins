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

package network::enterasys::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return $self->{cpu_avg}->{count} . " CPU(s) average usage is ";
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return sprintf(
        "CPU '%s' [%s] usage ",
        $options{instance_value}->{cpu_num},
        $options{instance_value}->{physicalName}
    );
}

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
                key_values => [ { name => 'cpu_5s' }, { name => 'cpu_num' }, { name => 'physicalName' } ],
                output_template => '%.2f %% (5s)',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{physicalName}, $self->{result_values}->{cpu_num}],
                        value => sprintf('%.2f', $self->{result_values}->{cpu_5s}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        },
        { label => 'core-1m', nlabel => 'core.cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_1m' }, { name => 'cpu_num' }, { name => 'physicalName' } ],
                output_template => '%.2f %% (1m)',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{physicalName}, $self->{result_values}->{cpu_num}],
                        value => sprintf('%.2f', $self->{result_values}->{cpu_1m}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        },
        { label => 'core-5m', nlabel => 'core.cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_5m' }, { name => 'cpu_num' }, { name => 'physicalName' } ],
                output_template => '%.2f %% (5m)',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{physicalName}, $self->{result_values}->{cpu_num}],
                        value => sprintf('%.2f', $self->{result_values}->{cpu_5m}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-entity-name:s'  => { name => 'filter_entity_name' },
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
        count => $count
    };
}

my $mapping = {
    cpu_5s => { oid => '.1.3.6.1.4.1.5624.1.2.49.1.1.1.1.2' }, # etsysResourceCpuLoad5sec
    cpu_1m => { oid => '.1.3.6.1.4.1.5624.1.2.49.1.1.1.1.3' }, # etsysResourceCpuLoad1min
    cpu_5m => { oid => '.1.3.6.1.4.1.5624.1.2.49.1.1.1.1.4' }  # etsysResourceCpuLoad5min
};
my $oid_etsysResourceCpuTable = '.1.3.6.1.4.1.5624.1.2.49.1.1.1';
my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_etsysResourceCpuTable,
        nothing_quit => 1
    );

    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};

    my $indexes = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{cpu_5m}->{oid}\.(\d+).(\d+)$/);
        my ($physicalIndex, $cpu_num) = ($1, $2);
        my $instance = $1 . '.' . $2;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $options{snmp}->load(oids => [ $oid_entPhysicalName . '.' . $physicalIndex ]) if (!defined($indexes->{$physicalIndex}));
        $indexes->{$physicalIndex} = 1;

        $self->{cpu_core}->{$instance} = {
            physicalIndex => $physicalIndex,
            cpu_num => $cpu_num,
            cpu_5s => $result->{cpu_5s} / 10,
            cpu_1m => $result->{cpu_1m} / 10,
            cpu_5m => $result->{cpu_5m} / 10
        };
    }

    if (scalar(keys %$indexes) > 0) {
        $snmp_result = $options{snmp}->get_leef();
        foreach (keys %{$self->{cpu_core}}) {
            my $entity_name = $snmp_result->{ $oid_entPhysicalName . '.' . $self->{cpu_core}->{$_}->{physicalIndex} };
            if (defined($self->{option_results}->{filter_entity_name}) && $self->{option_results}->{filter_entity_name} ne '' &&
                $entity_name !~ /$self->{option_results}->{filter_entity_name}/) {
                delete $self->{cpu_core}->{$_};
                next;
            }
            $self->{cpu_core}->{$_}->{physicalName} = $entity_name;
        }
    }

    $self->check_cpu_average();
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--filter-entity-name>

Filter entity name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'core-5s', 'core-1m', 'core-5m', 'average-5s', 'average-1m', 'average-5m'.

=back

=cut
