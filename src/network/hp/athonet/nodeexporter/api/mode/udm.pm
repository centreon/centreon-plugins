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

package network::hp::athonet::nodeexporter::api::mode::udm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(is_excluded);

sub prefix_diameter_output {
    my ($self, %options) = @_;

    return sprintf(
        "diameter stack '%s' origin host '%s' ",
        $options{instance_value}->{stack},
        $options{instance_value}->{originHost}
    );
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cluster repository '%s'",
        $options{instance_value}->{repository}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return sprintf(
        "cluster repository '%s' ",
        $options{instance_value}->{repository}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' ",
        $options{instance_value}->{node}
    );
}

sub prefix_cluster_metrics_output {
    my ($self, %options) = @_;

    return 'number of nodes ';
}

sub prefix_sbi_registration_output {
    my ($self, %options) = @_;

    return "SBI registration network function";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sbi_registration', type => 0, cb_prefix_output => 'prefix_sbi_registration_output', skipped_code => { -10 => 1 } },
        {
            name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok', 
            group => [
                { name => 'cluster_metrics', type => 0, cb_prefix_output => 'prefix_cluster_metrics_output', skipped_code => { -10 => 1 } },
                { name => 'nodes', type => 1, display_long => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'nodes are ok', skipped_code => { -10 => 1 } }
            ]
        },
        { name => 'diameters', type => 1, cb_prefix_output => 'prefix_diameter_output', message_multiple => 'All diameter connections are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'clusters-detected', display_ok => 0, nlabel => 'clusters.detected.count', set => {
                key_values => [ { name => 'clusters_detected' } ],
                output_template => 'Number of clusters detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cluster_metrics} = [
        { label => 'cluster-nodes-detected', nlabel => 'cluster.nodes.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_detected' } ],
                output_template => 'detected: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cluster-nodes-running', nlabel => 'cluster.nodes.running.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_running' }, { name => 'nodes_detected' } ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'nodes_detected', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cluster-nodes-notrunning', nlabel => 'cluster.nodes.notrunning.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_notrunning' }, { name => 'nodes_detected' } ],
                output_template => 'not running: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'nodes_detected', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'node-status', type => 2, critical_default => '%{status} =~ /notRunning/i', set => {
                key_values => [ { name => 'status' }, { name => 'repository' }, { name => 'node' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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

    $self->{maps_counters}->{diameters} = [
        { label => 'diameter-connection-status', type => 2, critical_default => '%{status} =~ /down/i', set => {
                key_values => [ { name => 'status' }, { name => 'originHost' }, { name => 'stack' } ],
                output_template => 'connection status: %s',
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
        'filter-cluster-repository:s' => { name => 'filter_cluster_repository' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $clusters = $options{custom}->query(queries => ['nf_data_layer_cluster_nodes{target_type="udm"}']);
    my $nodes = $options{custom}->query(queries => ['nf_data_layer_cluster_nodes_status{target_type="udm"}']);

    my $map_node_status = { 1 => 'running', 0 => 'notRunning' };
    my $map_registration_status = { 1 => 'registered', 0 => 'suspended' };
    my $map_interface_status = { 1 => 'up', 0 => 'down' };

    $self->{global} = { clusters_detected => 0 };
    $self->{clusters} = {};

    foreach my $cluster (@$clusters) {
        next if is_excluded($cluster->{metric}->{repository}, $self->{option_results}->{filter_cluster_repository});
 
        $self->{global}->{clusters_detected}++;

        $self->{clusters}->{ $cluster->{metric}->{repository} } = {
            repository => $cluster->{metric}->{repository},
            cluster_metrics => {
                nodes_detected => $cluster->{value}->[1],
                nodes_running => 0,
                nodes_notrunning => 0
            },
            nodes => {}
        };

        foreach my $node (@$nodes) {
            next if ($cluster->{metric}->{repository} ne $node->{metric}->{repository});

            $self->{clusters}->{ $cluster->{metric}->{repository} }->{nodes}->{ $node->{metric}->{node} } = {
                repository => $cluster->{metric}->{repository},
                node => $node->{metric}->{node},
                status => $map_node_status->{ $node->{value}->[1] }
            };
            $self->{clusters}->{ $cluster->{metric}->{repository} }->{cluster_metrics}->{'nodes_' . lc($map_node_status->{ $node->{value}->[1] })}++;
        }
    }

    my $response = $options{custom}->query(queries => ['diameter_peer_status{target_type="udm"}']);
    $self->{diameters} = {};
    my $id = 0;
    foreach (@$response) {
        $self->{diameters}->{$id} = {
            originHost => $_->{metric}->{orig_host},
            stack => $_->{metric}->{stack},
            status => $map_interface_status->{ $_->{value}->[1] }
        };
        
        $id++;
    }

    my $registration_infos = $options{custom}->query(queries => ['sbi_nrf_registration_status{target_type="udm"}']);

    $self->{sbi_registration} = { detected => 0, registered => 0, suspended => 0 };
    foreach my $info (@$registration_infos) {
        $self->{sbi_registration}->{status} = $map_registration_status->{ $info->{value}->[1] };
        $self->{sbi_registration}->{detected}++;
        $self->{sbi_registration}->{lc($map_registration_status->{ $info->{value}->[1] })}++;
    }
}

1;

__END__

=head1 MODE

Check unified data management.

=over 8

=item B<--filter-cluster-repository>

Filter clusters by repository name.

=item B<--unknown-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{repository}>, C<%{node}>.

=item B<--warning-node-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{repository}>, C<%{node}>.

=item B<--critical-node-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /notRunning/i>).
You can use the following variables: C<%{status}>, C<%{repository}>, C<%{node}>.

=item B<--unknown-diameter-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--warning-diameter-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--critical-diameter-connection-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /down/i>).
You can use the following variables: C<%{status}>, C<%{originHost}>, C<%{stack}>.

=item B<--unknown-sbi-nf-registration-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>.

=item B<--warning-sbi-nf-registration-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>.

=item B<--critical-sbi-nf-registration-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} =~ /suspended/i>).
You can use the following variables: C<%{status}>.

=item B<--warning-clusters-detected>

Thresholds.

=item B<--critical-clusters-detected>

Thresholds.

=item B<--warning-cluster-nodes-detected>

Thresholds.

=item B<--critical-cluster-nodes-detected>

Thresholds.

=item B<--warning-cluster-nodes-running>

Thresholds.

=item B<--critical-cluster-nodes-running>

Thresholds.

=item B<--warning-cluster-nodes-notrunning>

Thresholds.

=item B<--critical-cluster-nodes-notrunning>

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
