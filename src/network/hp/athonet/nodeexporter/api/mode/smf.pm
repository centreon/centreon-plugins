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

package network::hp::athonet::nodeexporter::api::mode::smf;

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

sub prefix_pfcp_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "PFCP local IP '%s' remote IP '%s' ",
        $options{instance_value}->{localIP},
        $options{instance_value}->{remoteIP}
    );
}

sub prefix_sbi_registration_output {
    my ($self, %options) = @_;

    return "SBI registration network function";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'sbi_registration', type => 0, cb_prefix_output => 'prefix_sbi_registration_output', skipped_code => { -10 => 1 } },
        { name => 'pfcp_nodes', type => 1, cb_prefix_output => 'prefix_pfcp_node_output', message_multiple => 'All PFCP nodes are ok', skipped_code => { -10 => 1 } },
        { name => 'blacklist_nodes', type => 1, cb_prefix_output => 'prefix_blacklist_node_output', message_multiple => 'All blacklisted nodes are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sessions', nlabel => 'smf.sessions.count', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'supi', nlabel => 'smf.supi.count', set => {
                key_values => [ { name => 'supi' } ],
                output_template => 'supi: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sbi_registration} = [
        { label => 'sbi-nf-registration-status', type => 2, critical_default => '%{status} =~ /suspended/i', set => {
                key_values => [ { name => 'status' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'sbi-nf-registration-detected', display_ok => 0, nlabel => 'sbi.nf.registration.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'sbi-nf-registration-registered', display_ok => 0, nlabel => 'sbi.nf.registration.registered.count', display_ok => 0, set => {
                key_values => [ { name => 'registered' }, { name => 'detected' } ],
                output_template => 'registered: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        },
        { label => 'sbi-nf-registration-suspended', display_ok => 0, nlabel => 'sbi.nf.registration.suspended.count', display_ok => 0, set => {
                key_values => [ { name => 'suspended' }, { name => 'detected' } ],
                output_template => 'suspended: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
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

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $response = $options{custom}->query(queries => ['sum(smf_sessions)']);
    $self->{global}->{sessions} = $response->[0]->{value}->[1];

    $response = $options{custom}->query(queries => ['smf_supi']);
    $self->{global}->{supi} = $response->[0]->{value}->[1];

    # TODO (need an example)
    #$response = $options{custom}->query(queries => ['smf_radius_server_state']);

    my $map_registration_status = { 1 => 'registered', 0 => 'suspended' };

    my $registration_infos = $options{custom}->query(queries => ['sbi_nrf_registration_status{target_type="smf"}']);
    $self->{sbi_registration} = { detected => 0, registered => 0, suspended => 0 };
    foreach my $info (@$registration_infos) {
        $self->{sbi_registration}->{status} = $map_registration_status->{ $info->{value}->[1] };
        $self->{sbi_registration}->{detected}++;
        $self->{sbi_registration}->{lc($map_registration_status->{ $info->{value}->[1] })}++;
    }

    my $map_node_status = { 1 => 'up', 2 => 'down' };

    $response = $options{custom}->query(queries => ['pfcp_node_status{target_type="smf"}']);
    $self->{pfcp_nodes} = {};
    foreach (@$response) {
        $self->{pfcp_nodes}->{ $_->{metric}->{local_ip} . ':' . $_->{metric}->{remote_ip} } = {
            localIP => $_->{metric}->{local_ip},
            remoteIP => $_->{metric}->{remote_ip},
            status => $map_node_status->{ $_->{value}->[1] }
        };
    }

    my $map_pfcp_peer_state_info = { 0 => 'no', 1 => 'yes' };
    $response = $options{custom}->query(queries => ['pfcp_peer_state_info{type="blacklist", target_type="smf"}']);
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

Check session management function.

=over 8

=item B<--unknown-sbi-nf-registration-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>.

=item B<--warning-sbi-nf-registration-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>.

=item B<--critical-sbi-nf-registration-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /suspended/i>).
You can use the following variables: C<%{status}>.

=item B<--unknown-pfcp-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--warning-pfcp-node-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{localIP}>, C<%{remoteIP}>.

=item B<--critical-pfcp-node-status>

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

=item B<--warning-sessions>

Thresholds.

=item B<--critical-sessions>

Thresholds.

=item B<--warning-supi>

Thresholds.

=item B<--critical-supi>

Thresholds.

=item B<--warning-sbi-nf-registration-detected>

Thresholds.

=item B<--critical-sbi-nf-registration-detected>

Thresholds.

=item B<--warning-sbi-nf-registration-registered>

Thresholds.

=item B<--critical-sbi-nf-registration-registered>

Thresholds.

=item B<--warning-sbi-nf-registration-suspended>

Thresholds.

=item B<--critical-sbi-nf-registration-suspended>

Thresholds.

=back

=cut
