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

package network::adva::fsp150::snmp::mode::systems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_system_output {
    my ($self, %options) = @_;

    return "system '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'systems', type => 1, cb_prefix_output => 'prefix_system_output', message_multiple => 'All systems are ok' }
    ];

    $self->{maps_counters}->{systems} = [
        { label => 'cpu-utilization-15min', nlabel => 'system.cpu.utilization.15min.percentage', set => {
                key_values => [
                    { name => 'cpu_average' }, { name => 'ne_name' }, { name => 'shelf_name' },
                    { name => 'slot_name' }, { name => 'display' }
                ],
                output_template => 'cpu usage: %.2f%% (15min)',
                closure_custom_perfdata => sub {
                    my ($self) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [
                            $self->{result_values}->{ne_name},
                            $self->{result_values}->{shelf_name},
                            $self->{result_values}->{slot_name}
                        ],
                        value => sprintf('%.2f', $self->{result_values}->{cpu_average}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0, max => 100
                    );
                }
            }
        },
        { label => 'memory-usage', nlabel => 'system.memory.usage.bytes', set => {
                key_values => [
                    { name => 'memory_used' }, { name => 'ne_name' }, { name => 'shelf_name' },
                    { name => 'slot_name' }, { name => 'display' }
                ],
                output_template => 'memory used: %s%s',
                output_change_bytes => 1,
                closure_custom_perfdata => sub {
                    my ($self) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'B',
                        instances => [
                            $self->{result_values}->{ne_name},
                            $self->{result_values}->{shelf_name},
                            $self->{result_values}->{slot_name}
                        ],
                        value => $self->{result_values}->{memory_used},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
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
        'filter-network-element:s' => { name => 'filter_network_element' }
    });

    return $self;
}

my $mapping = {
    cpu_average => { oid => '.1.3.6.1.4.1.2544.1.12.5.1.75.1.5' },  # f3CardStatsACU
    memory_used => { oid => '.1.3.6.1.4.1.2544.1.12.5.1.75.1.10' }  # f3CardStatsIMU (KB)
};
my $map_stat_index = {
    1 => '15min', 2 => '1day', 3 => 'rollover', 4 => '5min'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{cpu_average}->{oid} },
            { oid => $mapping->{memory_used}->{oid} }
        ],
        return_type => 1,
        nothing_quit => 1
    );

    my ($ne_indexes, $shelf_indexes, $slot_indexes) = ({}, {}, {});
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{cpu_average}->{oid}\.(\d+)\.(\d+)\.(\d+)\./);
        $ne_indexes->{$1} = 1;
        $shelf_indexes->{$1 . '.' . $2} = 1;
        $slot_indexes->{$1 . '.' . $2 . '.' . $3} = 1;
    }

    my $oid_slotEntityIndex = '.1.3.6.1.4.1.2544.1.12.3.1.3.1.2';
    my $oid_shelfEntityIndex = '.1.3.6.1.4.1.2544.1.12.3.1.2.1.2';
    my $oid_neName = '.1.3.6.1.4.1.2544.1.12.3.1.1.1.2';
    my $snmp_indexes = $options{snmp}->get_leef(
        oids => [
            map($oid_neName . '.' . $_, keys(%$ne_indexes)),
            map($oid_shelfEntityIndex . '.' . $_, keys(%$shelf_indexes)),
            map($oid_slotEntityIndex . '.' . $_, keys(%$slot_indexes))
        ]
    );

    my $entity_indexes = {};
    foreach (keys %$snmp_indexes) {
        $entity_indexes->{$snmp_indexes->{$_}} = 1 if (/^(?:$oid_shelfEntityIndex|$oid_slotEntityIndex)\./);
    }

    my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';
    my $snmp_entities = $options{snmp}->get_leef(
        oids => [
            map($oid_entPhysicalName . '.' . $_, keys(%$entity_indexes))
        ]
    );

    $self->{systems} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{cpu_average}->{oid}\.(\d+)\.(\d+)\.(\d+)\.1/); # we want 15min
        my $instance = $1 . '.' . $2 . '.' . $3;
        my $ne_name = $snmp_indexes->{ $oid_neName . '.' . $1 };
        my $shelf_name = $snmp_entities->{ $oid_entPhysicalName . '.' . $snmp_indexes->{ $oid_shelfEntityIndex . '.' . $1 . '.' . $2 } };
        my $slot_name = $snmp_entities->{ $oid_entPhysicalName . '.' . $snmp_indexes->{ $oid_slotEntityIndex . '.' . $1 . '.' . $2 . '.' . $3 } };

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance. '.1'
        );
        $result->{memory_used} *= 1024;
        my $display = $ne_name . ':' . $shelf_name . ':' . $slot_name;

        if (defined($self->{option_results}->{filter_network_element}) && $self->{option_results}->{filter_network_element} ne '' &&
            $ne_name !~ /$self->{option_results}->{filter_network_element}/) {
            $self->{output}->output_add(long_msg => "skipping system '" . $display . "': no matching filter.", debug => 1);
            next;
        }

        $self->{systems}->{$instance} = {
            display => $display,
            ne_name => $ne_name,
            shelf_name => $shelf_name,
            slot_name => $slot_name,
            %$result
        };
    }
}

1;

__END__

=head1 MODE

Check systems.

=over 8

=item B<--filter-network-elemet>

Filter by network element name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization-15min', 'memory-usage'.

=back

=cut
