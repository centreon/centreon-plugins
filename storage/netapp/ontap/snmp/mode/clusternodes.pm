#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package storage::netapp::ontap::snmp::mode::clusternodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_node_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "node status: %s",
        $self->{result_values}->{node_status}
    );
}

sub custom_bbu_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "nvram battery status: %s",
        $self->{result_values}->{bbu_status}
    );
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $diff_uptime = $options{new_datas}->{$self->{instance} . '_cpuUptime'} - $options{old_datas}->{$self->{instance} . '_cpuUptime'};
    my $diff_busy = $options{new_datas}->{$self->{instance} . '_cpuBusyTime'} - $options{old_datas}->{$self->{instance} . '_cpuBusyTime'};
    
    if ($diff_uptime == 0) {
        $self->{result_values}->{cpu_used} = 0;
    } else {
        $self->{result_values}->{cpu_used} = $diff_busy * 100 / $diff_uptime;
    }

    return 0;
}

sub custom_port_link_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "operational status: %s [admin: %s]",
        $self->{result_values}->{opstatus},
        $self->{result_values}->{admstatus}
    );
}

sub custom_port_health_output {
    my ($self, %options) = @_;

    return sprintf(
        "health: %s",
        $self->{result_values}->{health}
    );
}

sub node_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking node '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return sprintf(
        "port '%s' [role: %s] ",
        $options{instance_value}->{port_id},
        $options{instance_value}->{role}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output',
          indent_long_output => '    ', message_multiple => 'All nodes are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'env', type => 0, skipped_code => { -10 => 1 } },
                { name => 'ports', type => 1, cb_prefix_output => 'prefix_port_output', message_multiple => 'ports are ok', display_long => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        { label => 'node-status', type => 2, critical_default => '%{node_status} eq "clusterComLost"', set => {
                key_values => [
                    { name => 'node_status' }, { name => 'node_name' }
                ],
                closure_custom_output => $self->can('custom_node_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'bbu-status', type => 2, critical_default => '%{bbu_status} !~ /fullyCharged|ok/i', set => {
                key_values => [
                    { name => 'bbu_status' }, { name => 'node_name' }
                ],
                closure_custom_output => $self->can('custom_bbu_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
         { label => 'cpu-utilization', nlabel => 'node.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpuUptime', diff => 1 }, { name => 'cpuBusyTime', diff => 1 } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_template => 'cpu utilization: %.2f%%',
                output_use => 'cpu_used', threshold_use => 'cpu_used',
                perfdatas => [
                    { value => 'cpu_used', template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{env} = [
        { label => 'fan-failed', nlabel => 'node.hardware.fans.failed.count', set => {
                key_values => [ { name => 'envFailedFanCount' } ],
                output_template => 'number of fans failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'psu-failed', nlabel => 'node.hardware.power_supplies.failed.count', set => {
                key_values => [ { name => 'envFailedPSUCount' } ],
                output_template => 'number of power supplies failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'temperature-overrange', nlabel => 'node.hardware.temperatures.over_range.count', set => {
                key_values => [ { name => 'envOverTemp' } ],
                output_template => 'number of temperatures over range: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ports} = [
        { label => 'port-link-status', type => 2, critical_default => '%{admstatus} eq "up" and %{opstatus} ne "up"', set => {
                key_values => [
                    { name => 'admstatus' }, { name => 'opstatus' }, { name => 'port_id' }, { name => 'node_name' }
                ],
                closure_custom_output => $self->can('custom_port_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'port-health', type => 2, warning_default => '%{health} eq "degraded"', set => {
                key_values => [
                    { name => 'health' }, { name => 'port_id' }, { name => 'node_name' }
                ],
                closure_custom_output => $self->can('custom_port_health_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-node-name:s' => { name => 'filter_node_name' },
        'filter-port-id:s'   => { name => 'filter_port_id' },
        'filter-port-role:s' => { name => 'filter_port_role' }
    });

    return $self;
}

my $map_node_health = {
    0 => 'clusterComLost', 1 => 'clusterComOk'
};
my $map_nvram_status = {
    1 => 'ok', 2 => 'partiallyDischarged',
    3 => 'fullyDischarged', 4 => 'notPresent',
    5 => 'nearEndOfLife', 6 => 'atEndOfLife',
    7 => 'unknown', 8 => 'overCharged', 9 => 'fullyCharged'
};
my $map_port_admin = {
    0 => 'down', 1 => 'up'
};
my $map_port_state = {
    0 => 'undef', 1 => 'off', 2 => 'up', 3 => 'down'
};
my $map_port_health = {
    -1 => 'unknown', 0 => 'healthy', 1 => 'degraded'
};
my $map_port_role = {
    0 => 'undef', 1 => 'cluster', 2 => 'data',
    3 => 'node-mgmt', 4 => 'intercluster', 5 => 'cluster-mgmt'
};

my $mapping = {
    health            => { oid => '.1.3.6.1.4.1.789.1.25.2.1.11', map => $map_node_health }, # nodeHealth
    cpuUptime         => { oid => '.1.3.6.1.4.1.789.1.25.2.1.15' }, # nodeCpuUptime
    cpuBusyTime       => { oid => '.1.3.6.1.4.1.789.1.25.2.1.16' }, # nodeCpuBusyTime
    bbuStatus         => { oid => '.1.3.6.1.4.1.789.1.25.2.1.17', map => $map_nvram_status }, # nodeNvramBatteryStatus
    envOverTemp       => { oid => '.1.3.6.1.4.1.789.1.25.2.1.18' }, # nodeEnvOverTemperature
    envFailedFanCount => { oid => '.1.3.6.1.4.1.789.1.25.2.1.19' }, # nodeEnvFailedFanCount
    envFailedPSUCount => { oid => '.1.3.6.1.4.1.789.1.25.2.1.21' }  # nodeEnvFailedPowerSupplyCount
};
my $mapping_port = {
    port_id   => { oid => '.1.3.6.1.4.1.789.1.22.2.1.2' }, # netportPort
    role      => { oid => '.1.3.6.1.4.1.789.1.22.2.1.3', map => $map_port_role }, # netportRole
    opstatus  => { oid => '.1.3.6.1.4.1.789.1.22.2.1.4', map => $map_port_state }, # netportLinkState
    admstatus => { oid => '.1.3.6.1.4.1.789.1.22.2.1.14', map => $map_port_admin }, # netportUpAdmin
    health    => { oid => '.1.3.6.1.4.1.789.1.22.2.1.30', map => $map_port_health } # netportHealthStatus
};

sub add_ports {
    my ($self, %options) = @_;

    my $oid_netportNode = '.1.3.6.1.4.1.789.1.22.2.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_netportNode
    );
    my $instances = {};
    foreach (keys %$snmp_result) {
        next if (!defined($self->{nodes}->{ $snmp_result->{$_} }));

        /^$oid_netportNode\.(.*)$/;
        $instances->{$1} = $snmp_result->{$_};
    }

    return if (scalar(keys %$instances) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_port)) ],
        instances => [ keys %$instances ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %$instances) {
        my $result = $options{snmp}->map_instance(mapping => $mapping_port, results => $snmp_result, instance => $_);

        if (defined($self->{option_results}->{filter_port_id}) && $self->{option_results}->{filter_port_id} ne '' &&
            $result->{port_id} !~ /$self->{option_results}->{filter_port_id}/) {
            $self->{output}->output_add(long_msg => "skipping port '" . $result->{port_id} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_port_role}) && $self->{option_results}->{filter_port_role} ne '' &&
            $result->{role} !~ /$self->{option_results}->{filter_port_role}/) {
            $self->{output}->output_add(long_msg => "skipping port '" . $result->{port_id} . "'.", debug => 1);
            next;
        }

        $self->{nodes}->{ $instances->{$_} }->{ports}->{ $result->{port_id} } = $result;
        $self->{nodes}->{ $instances->{$_} }->{ports}->{ $result->{port_id} }->{node_name} = $instances->{$_};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_nodeName = '.1.3.6.1.4.1.789.1.25.2.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_nodeName,
        nothing_quit => 1
    );

    $self->{nodes} = {};
    foreach (keys %$snmp_result) {
        /$oid_nodeName\.(.*)$/;

        my $instance = $1;
        my $name = $snmp_result->{$_};
        if (defined($self->{option_results}->{filter_node_name}) && $self->{option_results}->{filter_node_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_node_name}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $name . "'.", debug => 1);
            next;
        }

        $self->{nodes}->{$name} = {
            instance => $instance,
            name => $name,
            status => { name => $name },
            ports => {}
        };
    }

    return if (scalar(keys %{$self->{nodes}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{nodes}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{nodes}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{nodes}->{$_}->{instance});

        $self->{nodes}->{$_}->{status}->{node_status} = $result->{node_status};
        $self->{nodes}->{$_}->{status}->{bbu_status} = $result->{bbu_status};

        $self->{nodes}->{$_}->{cpu} = {
            cpuUptime => $result->{cpuUptime},
            cpuBusyTime => $result->{cpuBusyTime}
        };
        $self->{nodes}->{$_}->{env} = {
            envOverTemp => $result->{envOverTemp},
            envFailedFanCount => $result->{envFailedFanCount},
            envFailedPSUCount => $result->{envFailedPSUCount}
        };
    }

    $self->add_ports(snmp => $options{snmp});

    $self->{cache_name} = 'netapp_ontap_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : 'all') . '_' .
            (defined($self->{option_results}->{filter_node_name}) ? $self->{option_results}->{filter_node_name} : 'all') . '_' .
            (defined($self->{option_results}->{filter_port_id}) ? $self->{option_results}->{filter_port_id} : 'all') . '_' .
            (defined($self->{option_results}->{filter_port_role}) ? $self->{option_results}->{filter_port_role} : 'all')
        );
}

1;

__END__

=head1 MODE

Check cluster nodes.

=over 8

=item B<--filter-node-name>

Filter nodes by name (can be a regexp).

=item B<--filter-port-id>

Filter ports by id (can be a regexp).

=item B<--filter-port-role>

Filter ports by role (can be a regexp).

=item B<--unknown-node-status>

Set unknown threshold for status.
Can used special variables like: %{node_status}, %{node_name}

=item B<--warning-node-status>

Set warning threshold for status.
Can used special variables like: %{node_status}, %{node_name}

=item B<--critical-node-status>

Set critical threshold for status (Default: '%{node_status} eq "clusterComLost"').
Can used special variables like: %{node_status}, %{node_name}

=item B<--unknown-bbu-status>

Set unknown threshold for status.
Can used special variables like: %{bbu_status}, %{node_name}

=item B<--warning-bbu-status>

Set warning threshold for status.
Can used special variables like: %{bbu_status}, %{node_name}

=item B<--critical-bbu-status>

Set critical threshold for status (Default: '%{bbu_status} !~ /fullyCharged|ok/i').
Can used special variables like: %{bbu_status}, %{node_name}

=item B<--unknown-port-link-status>

Set unknown threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{port_id}, %{node_name}

=item B<--warning-port-link-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{port_id}, %{node_name}

=item B<--critical-port-link-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{port_id}, %{node_name}

=item B<--unknown-port-health>

Set unknown threshold for status.
Can used special variables like: %{health}, %{port_id}, %{node_name}

=item B<--warning-port-health>

Set warning threshold for status (Default: '%{health} eq "degraded"').
Can used special variables like: %{health}, %{port_id}, %{node_name}

=item B<--critical-port-health>

Set critical threshold for status.
Can used special variables like: %{health}, %{port_id}, %{node_name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization', 'temperature-overrange', 'fan-failed', 'psu-failed'.

=back

=cut
