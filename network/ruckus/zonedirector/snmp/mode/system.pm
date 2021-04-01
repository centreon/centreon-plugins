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

package network::ruckus::zonedirector::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('system status is %s [peer status: %s]',
        $self->{result_values}->{system_status},
        $self->{result_values}->{peer_connected_status}
    );
}

sub system_long_output {
    my ($self, %options) = @_;

    return 'checking system ';
}

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'ram total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 3, cb_long_output => 'system_long_output',
          indent_long_output => '    ',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, skipped_code => { -10 => 1 } },
                { name => 'connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'system_status' }, { name => 'peer_connected_status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-utilization', nlabel => 'system.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_util' } ],
                output_template => 'cpu usage: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'system.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'system.memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'system.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'ram used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{connection} = [
        { label => 'connection-accesspoints', nlabel => 'system.connection.accesspoints.count', set => {
                key_values => [ { name => 'ap' } ],
                output_template => 'access points connections: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'connection-client-devices-authorized', nlabel => 'system.connection.client.devices.authorized.count', set => {
                key_values => [ { name => 'authorized_clients' } ],
                output_template => 'client devices authorized connections: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'connection-rogue-devices', nlabel => 'system.connection.rogue.devices.count', display_ok => 0, set => {
                key_values => [ { name => 'rogues' } ],
                output_template => 'rogue devices connections: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'system.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'system.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $map_system_status = {
    1 => 'master', 2 => 'standby', 3 => 'noredundancy'
};
my $map_peer_connected_status = {
    1 => 'connected', 2 => 'disconnected'
};

my $mapping = {
    system_status         => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.1.30', map => $map_system_status },  # ruckusZDSystemStatus
    peer_connected_status => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.1.31', map => $map_peer_connected_status },  # ruckusZDSystemPeerConnectedStatus
    cpu_util              => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.5.58' },  # ruckusZDSystemCPUUtil
    memory_used_prct      => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.5.59' },  # ruckusZDSystemMemoryUtil (%)
    memory_size           => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.5.60' },  # ruckusZDSystemMemorySize (MB)
    ap                    => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.15.1' },  # ruckusZDSystemStatsNumAP
    authorized_clients    => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.15.2' },  # ruckusZDSystemStatsNumSta
    rogues                => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.15.3' },  # ruckusZDSystemStatsNumRogue
    traffic_in            => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.15.6' }, # ruckusZDSystemStatsWLANTotalRxBytes
    traffic_out           => { oid => '.1.3.6.1.4.1.25053.1.2.1.1.1.15.9' }  # ruckusZDSystemStatsWLANTotalTxBytes
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    my $memory_total = $result->{memory_size} * 1024 * 1024;
    my $memory_used = $result->{memory_used_prct} * $memory_total / 100;
    
    $self->{system}->{global} = {
        status => {
            system_status => $result->{system_status},
            peer_connected_status => $result->{peer_connected_status}
        },
        cpu => { cpu_util => $result->{cpu_util} },
        memory => {
            used => $memory_used,
            free => $memory_total - $memory_used,
            prct_used => $result->{memory_used_prct},
            prct_free => 100 - $result->{memory_used_prct},
            total => $memory_total
        },
        connection => {
            ap => $result->{ap},
            authorized_clients => $result->{authorized_clients},
            rogues => $result->{rogues}
        },
        traffic => {
            traffic_in => $result->{traffic_in} * 8,
            traffic_out => $result->{traffic_out} * 8
        }
    };

    $self->{cache_name} = 'ruckus_zd_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters_block}) ? md5_hex($self->{option_results}->{filter_counters_block}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{system_status}, %{peer_connected_status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{system_status}, %{peer_connected_status}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{system_status}, %{peer_connected_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-usage', 'usage-free', 'usage-prct', 'traffic-in', 'traffic-out',
'cpu-utilization', 'connection-accesspoints', 'connection-client-devices-authorized',
'connection-rogue-devices'.

=back

=cut
