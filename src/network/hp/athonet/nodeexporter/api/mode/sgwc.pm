#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::hp::athonet::nodeexporter::api::mode::sgwc;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_blacklist_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "Peer remote IP '%s' target type '%s' ",
        $options{instance_value}->{remoteIP},
        $options{instance_value}->{targetType}
    );
}

sub prefix_gtpc_output {
    my ($self, %options) = @_;

    return sprintf(
        "GTP-C local IP '%s' remote IP '%s' ",
        $options{instance_value}->{localIP},
        $options{instance_value}->{remoteIP}
    );
}

sub prefix_pfcp_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "PFCP local IP '%s' remote IP '%s' ",
        $options{instance_value}->{localIP},
        $options{instance_value}->{remoteIP}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'pfcp_nodes', type => 1, cb_prefix_output => 'prefix_pfcp_node_output', message_multiple => 'All PFCP nodes are ok', skipped_code => { -10 => 1 } },
        { name => 'gtpc', type => 1, cb_prefix_output => 'prefix_gtpc_output', message_multiple => 'All GTP-C connections are ok', skipped_code => { -10 => 1 } },
        { name => 'blacklist_nodes', type => 1, cb_prefix_output => 'prefix_blacklist_node_output', message_multiple => 'All blacklisted nodes are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'ue', nlabel => 'sgwc.ue.count', set => {
                key_values => [ { name => 'sgw_ue_fsm' } ],
                output_template => 'UE: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'dfb', nlabel => 'sgwc.dfb.count', set => {
                key_values => [ { name => 'sgw_dfb_fsm' } ],
                output_template => 'default bearers: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{pfcp_nodes} = [
        { label => 'pfcp-node-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'localIP' }, { name => 'remoteIP' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{gtpc} = [
        { label => 'gtpc-connection-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'localIP' }, { name => 'remoteIP' } ],
                output_template => 'connection status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{blacklist_nodes} = [
        { label => 'blacklist-node-status', type => 2, critical_default => '%{isBlacklisted} =~ /yes/i', set => {
                key_values => [ { name => 'isBlacklisted' }, { name => 'blacklisted' }, { name => 'remoteIP' }, { name => 'targetType' } ],
                output_template => 'is blacklisted: %s',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => 'peer.blacklisted.count',
                        instances => [$self->{result_values}->{targetType}, $self->{result_values}->{remoteIP}],
                        value => $self->{result_values}->{blacklisted},
                        min => 0
                    );
                },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $response = $options{custom}->query(queries => ['sgw_ue_fsm']);
    $self->{global}->{sgw_ue_fsm} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['sgw_dfb_fsm']);
    $self->{global}->{sgw_dfb_fsm} = $response->[0]->{value}->[1];

    my $map_node_status = { 1 => 'up', 0 => 'down' };

    $response = $options{custom}->query(queries => ['pfcp_node_status{target_type="sgwc"}']);
    $self->{pfcp_nodes} = {};
    foreach (@$response) {
        $self->{pfcp_nodes}->{ $_->{metric}->{local_ip} . ':' . $_->{metric}->{remote_ip} } = {
            localIP => $_->{metric}->{local_ip},
            remoteIP => $_->{metric}->{remote_ip},
            status => $map_node_status->{ $_->{value}->[1] }
        };
    }

    my $map_interface_status = { 1 => 'up', 0 => 'down' };

    $response = $options{custom}->query(queries => ['gtpc_peer_status{target_type="sgwc"}']);
    $self->{gtpc} = {};
    foreach (@$response) {
        $self->{gtpc}->{ $_->{metric}->{local_ip} . ':' . $_->{metric}->{remote_ip} } = {
            localIP => $_->{metric}->{local_ip},
            remoteIP => $_->{metric}->{remote_ip},
            status => $map_interface_status->{ $_->{value}->[1] }
        };
    }

    my $map_pfcp_peer_state_info = { 0 => 'no', 1 => 'yes' };
    $response = $options{custom}->query(queries => ['pfcp_peer_state_info{type="blacklist", target_type="sgwc"}']);
    $self->{blacklist_nodes} = {};
    foreach (@$response) {
        $self->{blacklist_nodes}->{ $_->{metric}->{target_type} . ':' . $_->{metric}->{remote} } = {
            targetType => $_->{metric}->{target_type},
            remoteIP => $_->{metric}->{remote},
            isBlacklisted => $map_pfcp_peer_state_info->{ $_->{value}->[1] },
            blacklisted => $_->{value}->[1]
        };
    }
}

1;

__END__

=head1 MODE

Check serving gateway control plane function.

=over 8

=item B<--unknown-pfcp-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--warning-pfcp-node-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--critical-pfcp-node-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--unknown-gtpc-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--warning-gtpc-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--critical-gtpc-connection-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--unknown-blacklist-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{isBlacklisted}>, C<%{remoteIP}>, C<%{targetType}>.

=item B<--warning-blacklist-node-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{isBlacklisted}>, C<%{remoteIP}>, C<%{targetType}>.

=item B<--critical-blacklist-node-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{isBlacklisted} =~ /yes/i>).
You can use the following variables: C<%{isBlacklisted}>, C<%{remoteIP}>, C<%{targetType}>.

=item B<--warning-ue>

Thresholds.

=item B<--critical-ue>

Thresholds.

=item B<--warning-dfb>

Thresholds.

=item B<--critical-dfb>

Thresholds.

=back

=cut
