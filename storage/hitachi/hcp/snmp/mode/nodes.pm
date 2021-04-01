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

package storage::hitachi::hcp::snmp::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_node_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "node status: %s",
        $self->{result_values}->{node_status}
    );
}

sub custom_nic_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "nic status: %s",
        $self->{result_values}->{nic_status}
    );
}

sub custom_san_path_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "san path status: %s",
        $self->{result_values}->{san_path_status}
    );
}

sub custom_bbu_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "battery backup unit status: %s",
        $self->{result_values}->{bbu_status}
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub node_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking node '%s' [ip address: %s]",
        $options{instance_value}->{node_id},
        $options{instance_value}->{ip_address}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' [ip address: %s] ",
        $options{instance_value}->{node_id},
        $options{instance_value}->{ip_address}
    );
}

sub prefix_temperature_output {
    my ($self, %options) = @_;

    return "temperature '" . $options{instance_value}->{name} . "' ";
}

sub prefix_fan_output {
    my ($self, %options) = @_;

    return "fan '" . $options{instance_value}->{name} . "' ";
}

sub prefix_voltage_output {
    my ($self, %options) = @_;

    return "voltage '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output',
          indent_long_output => '    ', message_multiple => 'All nodes are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } },
                { name => 'temperatures', type => 1, cb_prefix_output => 'prefix_temperature_output', skipped_code => { -10 => 1 } },
                { name => 'fans', type => 1, cb_prefix_output => 'prefix_fan_output', skipped_code => { -10 => 1 } },
                { name => 'voltages', type => 1, cb_prefix_output => 'prefix_voltage_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        { label => 'node-status', type => 2, critical_default => '%{node_status} eq "unavailable"', set => {
                key_values => [
                    { name => 'node_status' }, { name => 'node_id' }
                ],
                closure_custom_output => $self->can('custom_node_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'nic-status', type => 2, critical_default => '%{nic_status} eq "failed"', set => {
                key_values => [
                    { name => 'nic_status' }, { name => 'node_id' }
                ],
                closure_custom_output => $self->can('custom_nic_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'san-path-status', type => 2, critical_default => '%{san_path_status} eq "error"', set => {
                key_values => [
                    { name => 'san_path_status' }, { name => 'node_id' }
                ],
                closure_custom_output => $self->can('custom_san_path_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'bbu-status', type => 2, critical_default => '%{bbu_status} !~ /healthy/i', set => {
                key_values => [
                    { name => 'bbu_status' }, { name => 'node_id' }
                ],
                closure_custom_output => $self->can('custom_bbu_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'node.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'node.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'node.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{temperatures} = [
        { label => 'sensor-temperature', nlabel => 'node.sensor.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'value' } ],
                output_template => 'is %s C',
                perfdatas => [
                    { template => '%s', unit => 'C', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{fans} = [
        { label => 'sensor-fan-speed', nlabel => 'node.sensor.fan.speed.rpm', display_ok => 0, set => {
                key_values => [ { name => 'value' } ],
                output_template => 'is %s rpm',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'rpm', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{voltages} = [
        { label => 'sensor-voltage', nlabel => 'node.sensor.voltage.volt', display_ok => 0, set => {
                key_values => [ { name => 'value' } ],
                output_template => 'is %s V',
                perfdatas => [
                    { template => '%s', unit => 'V', label_extra_instance => 1 }
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
        'filter-node-id:s' => { name => 'filter_node_id' }
    });

    return $self;
}

my $map_node_status = {
    0 => 'unavailable', 4 => 'available'
};
my $map_nic_failure = {
    1 => 'error', # yes
    2 => 'ok' # no
};
my $map_san_path_status = {
    0 => 'error', 1 => 'rain', 2 => 'sanWithoutMultipath', 3 => 'sanGood', 4 => 'sanDegradedToOne'
};
my $mapping = {
    space_free      => { oid => '.1.3.6.1.4.1.116.5.46.1.1.1.4' },  # nodeAvailability
    space_total     => { oid => '.1.3.6.1.4.1.116.5.46.1.1.1.5' },  # nodeCapacity
    node_status     => { oid => '.1.3.6.1.4.1.116.5.46.1.1.1.7', map => $map_node_status },  # nodeStatus
    nic_status      => { oid => '.1.3.6.1.4.1.116.5.46.1.1.1.11', map => $map_nic_failure }, # nodeNicFailure
    san_path_status => { oid => '.1.3.6.1.4.1.116.5.46.1.1.1.12', map => $map_san_path_status }, # nodeSANStatus
    bbu_status      => { oid => '.1.3.6.1.4.1.116.5.46.1.7.1.1' }   # bbuBroken
};
my $mapping_temperature = {
    name  => { oid => '.1.3.6.1.4.1.116.5.46.1.2.1.1' }, # ipmiTemperatureName
    value => { oid => '.1.3.6.1.4.1.116.5.46.1.2.1.2' }  # ipmiTemperatureDetailedStatus (eg: "25.0C (77.0F); (range 0.0-43.0C)")
};
my $oid_temperature_entry = '.1.3.6.1.4.1.116.5.46.1.2.1'; # hcpIpmiTemperatureNodeTableEntry

my $mapping_fan = {
    name  => { oid => '.1.3.6.1.4.1.116.5.46.1.4.1.1' }, # ipmiFanName
    value => { oid => '.1.3.6.1.4.1.116.5.46.1.4.1.2' }  # ipmiFanDetailedStatus (eg: "5100.0 RPM")
};
my $oid_fan_entry = '.1.3.6.1.4.1.116.5.46.1.4.1'; # hcpIpmiFanNodeTableEntry

my $mapping_voltage = {
    name  => { oid => '.1.3.6.1.4.1.116.5.46.1.6.1.1' }, # ipmiVoltageName
    value => { oid => '.1.3.6.1.4.1.116.5.46.1.6.1.2' }  # ipmiVoltageDetailedStatus (eg: "1.22 Volts (1.08-1.32 Volts)")
};
my $oid_voltage_entry = '.1.3.6.1.4.1.116.5.46.1.6.1'; # hcpIpmiVoltageNodeTableEntry

sub add_temperatures {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_temperature_entry);
    foreach (keys %$snmp_result) {
        next if (! /$mapping_temperature->{value}->{oid}\.(\d+)\.(\d+)$/);
        my ($number, $index) = ($1, $2);
        next if (!defined($self->{nodes}->{$number}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_temperature, results => $snmp_result, instance => $number . '.' . $index);
        my $value;
        $value = $1 if ($result->{value} =~ /^\s*([0-9\.]+)\s*C/);
        $self->{nodes}->{$number}->{temperatures}->{ $result->{name} } = {
            name => $result->{name},
            value => $value
        };
    }
}

sub add_fans {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_fan_entry);
    foreach (keys %$snmp_result) {
        next if (! /$mapping_fan->{value}->{oid}\.(\d+)\.(\d+)$/);
        my ($number, $index) = ($1, $2);
        next if (!defined($self->{nodes}->{$number}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_fan, results => $snmp_result, instance => $number . '.' . $index);
        my $value;
        $value = $1 if ($result->{value} =~ /^\s*([0-9]+)/);
        $self->{nodes}->{$number}->{fans}->{ $result->{name} } = {
            name => $result->{name},
            value => $value
        };
    }
}

sub add_voltages {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_voltage_entry);
    foreach (keys %$snmp_result) {
        next if (! /$mapping_voltage->{value}->{oid}\.(\d+)\.(\d+)$/);
        my ($number, $index) = ($1, $2);
        next if (!defined($self->{nodes}->{$number}));

        my $result = $options{snmp}->map_instance(mapping => $mapping_voltage, results => $snmp_result, instance => $number . '.' . $index);
        my $value;
        $value = $1 if ($result->{value} =~ /^\s*([0-9\.]+)/);
        $self->{nodes}->{$number}->{voltages}->{ $result->{name} } = {
            name => $result->{name},
            value => $value
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_nodeIP = '.1.3.6.1.4.1.116.5.46.1.1.1.2';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_nodeIP,
        nothing_quit => 1
    );

    $self->{nodes} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        my $number = $1;

        if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $number !~ /$self->{option_results}->{filter_node_id}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $number . "'.", debug => 1);
            next;
        }

        $self->{nodes}->{$number} = {
            node_id => $number,
            ip_address => $snmp_result->{$_},
            status => { node_id => $number },
            space => {},
            temperatures => {},
            fans => {}
        };
    }

    return if (scalar(keys %{$self->{nodes}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %{$self->{nodes}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{nodes}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{nodes}->{$_}->{status}->{node_status} = $result->{node_status};
        $self->{nodes}->{$_}->{status}->{nic_status} = $result->{nic_status};
        $self->{nodes}->{$_}->{status}->{san_path_status} = $result->{san_path_status};
        $self->{nodes}->{$_}->{status}->{bbu_status} = $result->{bbu_status};

        next if (!defined($result->{space_total}));

        $self->{nodes}->{$_}->{space}->{total} = $result->{space_total};
        $self->{nodes}->{$_}->{space}->{free} = $result->{space_free};
        $self->{nodes}->{$_}->{space}->{used} = $result->{space_total} - $result->{space_free};
        $self->{nodes}->{$_}->{space}->{prct_free} = $result->{space_free} * 100 / $result->{space_total};
        $self->{nodes}->{$_}->{space}->{prct_used} = 100 - $self->{nodes}->{$_}->{space}->{prct_free};
    }

    $self->add_temperatures(snmp => $options{snmp});
    $self->add_fans(snmp => $options{snmp});
    $self->add_voltages(snmp => $options{snmp});
}

1;

__END__

=head1 MODE

Check nodes.

=over 8

=item B<--filter-node-id>

Filter nodes by id (can be a regexp).

=item B<--unknown-node-status>

Set unknown threshold for status.
Can used special variables like: %{node_status}, %{node_id}

=item B<--warning-node-status>

Set warning threshold for status.
Can used special variables like: %{node_status}, %{node_id}

=item B<--critical-node-status>

Set critical threshold for status (Default: '%{node_status} eq "unavailable"').
Can used special variables like: %{node_status}, %{node_id}

=item B<--unknown-nic-status>

Set unknown threshold for status.
Can used special variables like: %{nic_status}, %{node_id}

=item B<--warning-nic-status>

Set warning threshold for status.
Can used special variables like: %{nic_status}, %{node_id}

=item B<--critical-nic-status>

Set critical threshold for status (Default: '%{nic_status} eq "failed"').
Can used special variables like: %{nic_status}, %{node_id}

=item B<--unknown-san-path-status>

Set unknown threshold for status.
Can used special variables like: %{san_path_status}, %{node_id}

=item B<--warning-san-path-status>

Set warning threshold for status.
Can used special variables like: %{san_path_status}, %{node_id}

=item B<--critical-san-path-status>

Set critical threshold for status (Default: '%{san_path_status} eq "error"').
Can used special variables like: %{san_path_status}, %{node_id}

=item B<--unknown-bbu-status>

Set unknown threshold for status.
Can used special variables like: %{bbu_status}, %{node_id}

=item B<--warning-bbu-status>

Set warning threshold for status.
Can used special variables like: %{bbu_status}, %{node_id}

=item B<--critical-bbu-status>

Set critical threshold for status (Default: '%{bbu_status} !~ /healthy/i').
Can used special variables like: %{bbu_status}, %{node_id}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage-prct', 'space-usage', 'space-usage-free',
'sensor-voltage' (V), 'sensor-temperature' (C), 'sensor-fan-speed' (rpm).

=back

=cut
