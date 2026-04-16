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

package network::hp::athonet::nodeexporter::api::mode::upf;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

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
        { name => 'pfcp_nodes', type => 1, cb_prefix_output => 'prefix_pfcp_node_output', message_multiple => 'All PFCP nodes are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'upf-fpcf-nodes-detected', display_ok => 0, nlabel => 'upf.pfcp.nodes.detected.count', set => {
                key_values => [ { name => 'fpcp_nodes_detected' } ],
                output_template => 'fpcf nodes detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'upf-sessions', nlabel => 'upf.sessions.count', set => {
                key_values => [ { name => 'upf_sessions' } ],
                output_template => 'sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'upf-gtpu-interfaces', nlabel => 'upf.gtpu.interfaces.count', set => {
                key_values => [ { name => 'upf_gtpu_ifaces' } ],
                output_template => 'GTP-U interfaces: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'upf-ip-interfaces', nlabel => 'upf.ip.interfaces.count', set => {
                key_values => [ { name => 'upf_ip_ifaces' } ],
                output_template => 'IP interfaces: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'upf-dnn', nlabel => 'upf.dnn.count', set => {
                key_values => [ { name => 'upf_apn_dnn_total' } ],
                output_template => 'DNN: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{pfcp_nodes} = [
        { label => 'upf-pfcp-node-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'localIP' }, { name => 'remoteIP' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { fpcp_nodes_detected => 0 };

    my $response = $options{custom}->query(queries => ['upf_sessions']);
    $self->{global}->{upf_sessions} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['upf_gtpu_ifaces']);
    $self->{global}->{upf_gtpu_ifaces} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['upf_ip_ifaces']);
    $self->{global}->{upf_ip_ifaces} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['upf_apn_dnn_total']);
    $self->{global}->{upf_apn_dnn_total} = $response->[0]->{value}->[1];

    my $map_node_status = { 1 => 'up', 2 => 'down' };

    $response = $options{custom}->query(queries => ['pfcp_node_status{target_type="upf"}']);
    $self->{pfcp_nodes} = {};
    foreach (@$response) {
        $self->{pfcp_nodes}->{ $_->{metric}->{local_ip} . ':' . $_->{metric}->{remote_ip} } = {
            localIP => $_->{metric}->{local_ip},
            remoteIP => $_->{metric}->{remote_ip},
            status => $map_node_status->{ $_->{value}->[1] }
        };
        $self->{global}->{fpcp_nodes_detected}++;
    }
}

1;

__END__

=head1 MODE

Check user plane function.

=over 8

=item B<--unknown-upf-pfcp-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--warning-upf-pfcp-node-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--critical-upf-pfcp-node-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--warning-upf-fpcf-nodes-detected>

Thresholds.

=item B<--critical-upf-fpcf-nodes-detected>

Thresholds.

=item B<--warning-upf-sessions>

Thresholds.

=item B<--critical-upf-sessions>

Thresholds.

=item B<--warning-upf-gtpu-interfaces>

Thresholds.

=item B<--critical-upf-gtpu-interfaces>

Thresholds.

=item B<--warning-upf-ip-interfaces>

Thresholds.

=item B<--critical-upf-ip-interfaces>

Thresholds.

=item B<--warning-upf-dnn>

Thresholds.

=item B<--critical-upf-dnn>

Thresholds.

=back

=cut
