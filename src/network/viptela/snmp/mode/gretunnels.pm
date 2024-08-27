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

package network::viptela::snmp::mode::gretunnels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);
use Socket;

sub custom_packets_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{sourceIp},
            $self->{result_values}->{destIp}
        ],
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub tunnel_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking gre tunnel [src: %s] [dst: %s]",
        $options{instance_value}->{sourceIp}, 
        $options{instance_value}->{destIp}
    );
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;

    return sprintf(
        "gre tunnel [src: %s] [dst: %s] ",
        $options{instance_value}->{sourceIp}, 
        $options{instance_value}->{destIp}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of gre tunnels ';
}

sub prefix_packet_output {
    my ($self, %options) = @_;

    return 'packets ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'tunnels', type => 3, cb_prefix_output => 'prefix_tunnel_output', cb_long_output => 'tunnel_long_output',
          indent_long_output => '    ', message_multiple => 'All gre tunnels are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'packet', type => 0, cb_prefix_output => 'prefix_packet_output', skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'gretunnels-detected', display_ok => 0, nlabel => 'gre_tunnels.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'gretunnels-up', display_ok => 0, nlabel => 'gre_tunnels.operational.up.count', set => {
                key_values => [ { name => 'oper_up' } ],
                output_template => 'up: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'gretunnels-down', display_ok => 0, nlabel => 'gre_tunnels.operational.down.count', set => {
                key_values => [ { name => 'oper_down' } ],
                output_template => 'down: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'gretunnels-invalid', display_ok => 0, nlabel => 'gre_tunnels.operational.invalid.count', set => {
                key_values => [ { name => 'oper_invalid' } ],
                output_template => 'invalid: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{adminState} eq "up" and %{operState} ne "up"',
            set => {
                key_values => [
                    { name => 'adminState' }, { name => 'operState' },
                    { name => 'sourceIp' }, { name => 'destIp' }
                ],
                output_template => "status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{packet} = [
        { label => 'gretunnel-packets-in', nlabel => 'gre_tunnel.packets.in.count', set => {
                key_values => [ { name => 'packetsIn', diff => 1 }, { name => 'sourceIp' }, { name => 'destIp' } ],
                output_template => 'in: %s',
                closure_custom_perfdata => $self->can('custom_packets_perfdata')
            }
        },
        { label => 'gretunnel-packets-out', nlabel => 'gre_tunnel.packets.out.count', set => {
                key_values => [ { name => 'packetsOut', diff => 1 }, { name => 'sourceIp' }, { name => 'destIp' } ],
                output_template => 'out: %s',
                closure_custom_perfdata => $self->can('custom_packets_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-src-ip:s'  => { name => 'filter_src_ip' },
        'filter-dest-ip:s' => { name => 'filter_dest_ip' }
    });

    return $self;
}

my $map_status = {
    0 => 'down', 1 => 'up', 2 => 'invalid'
};

my $mapping_name = {
    sourceIp => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.3' }, # tunnelGreKeepalivesSourceIp
    destIp   => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.4' }  # tunnelGreKeepalivesDestIp
};
my $mapping = {
    adminState => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.5', map => $map_status }, # tunnelGreKeepalivesAdminState
    operState  => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.6', map => $map_status }, # tunnelGreKeepalivesOperState
    packetsOut => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.10' }, # tunnelGreKeepalivesTxPackets
    packetsIn  => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.11' }  # tunnelGreKeepalivesRxPackets
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => 'Need to use SNMP v2c or v3.');
        $self->{output}->option_exit();
    }

    $self->{global} = { detected => 0, oper_up => 0, oper_down => 0, oper_invalid => 0 };
    $self->{tunnels} = {};

    my $oid_tunnelTable = '.1.3.6.1.4.1.41916.4.5.2'; # tunnelGreKeepalivesTable
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_tunnelTable,
        start => $mapping_name->{sourceIp}->{oid},
        end => $mapping_name->{destIp}->{oid},
        nothing_quit => 1
    );
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_name->{sourceIp}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_name, results => $snmp_result, instance => $instance);
        $result->{sourceIp} = inet_ntoa($result->{sourceIp});
        $result->{destIp} = inet_ntoa($result->{destIp});
        
        next if (defined($self->{option_results}->{filter_src_ip}) && $self->{option_results}->{filter_src_ip} ne '' &&
            $result->{sourceIp} !~ /$self->{option_results}->{filter_src_ip}/);
        next if (defined($self->{option_results}->{filter_dest_ip}) && $self->{option_results}->{filter_dest_ip} ne '' &&
            $result->{destIp} !~ /$self->{option_results}->{filter_dest_ip}/);

        $self->{tunnels}->{$instance} = {
            %$result,
            status => $result,
            packet => $result
        };
    }

    return if (scalar(keys %{$self->{tunnels}}) <= 0);
    
    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [ map($_, keys %{$self->{tunnels}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{tunnels}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{tunnels}->{$_}->{status}->{adminState} = $result->{adminState};
        $self->{tunnels}->{$_}->{status}->{operState} = $result->{operState};

        $self->{tunnels}->{$_}->{packet}->{packetsOut} = $result->{packetsOut};
        $self->{tunnels}->{$_}->{packet}->{packetsIn} = $result->{packetsIn};

        $self->{global}->{detected}++;
        $self->{global}->{ 'oper_' . $result->{operState} }++;
    }

    $self->{cache_name} = 'viptela_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : 'all') .
            (defined($self->{option_results}->{filter_src_ip}) ? $self->{option_results}->{filter_src_ip} : 'all') .
            (defined($self->{option_results}->{filter_dest_ip}) ? $self->{option_results}->{filter_dest_ip} : 'all')
        );
}

1;

__END__

=head1 MODE

Check GRE tunnels.

=over 8

=item B<--filter-src-ip>

Filter tunnels by source ip address.

=item B<--filter-dest-ip>

Filter tunnels by destination ip address.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{adminState}, %{operState}, %{sourceIp}, %{destIp}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{adminState}, %{operState}, %{sourceIp}, %{destIp}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{adminState} eq "up" and %{operState} ne "up"').
You can use the following variables: %{adminState}, %{operState}, %{sourceIp}, %{destIp}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'gretunnels-detected', 'gretunnels-up', 'gretunnels-down', 'gretunnels-invalid',
'gretunnel-packets-in', 'gretunnel-packets-out'.

=back

=cut
