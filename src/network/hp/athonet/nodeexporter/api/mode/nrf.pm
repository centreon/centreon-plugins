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

package network::hp::athonet::nodeexporter::api::mode::nrf;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;

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

sub prefix_registration_output {
    my ($self, %options) = @_;

    return sprintf(
        "registration network function '%s' ",
        $options{instance_value}->{nfType}
    );
}

sub prefix_global_registration_output {
    my ($self, %options) = @_;

    return 'Number of network function registrations ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'global_registration', type => 0, cb_prefix_output => 'prefix_global_registration_output', skipped_code => { -10 => 1 } },
        { name => 'registrations', type => 1, cb_prefix_output => 'prefix_registration_output', message_multiple => 'All registration network functions are ok', skipped_code => { -10 => 1 } },
        {
            name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok',
            group => [
                { name => 'cluster_metrics', type => 0, cb_prefix_output => 'prefix_cluster_metrics_output' },
                { name => 'nodes', type => 1, display_long => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'nodes are ok', skipped_code => { -10 => 1 } }
            ]
        }
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

    $self->{maps_counters}->{global_registration} = [
        { label => 'nf-registrations-detected', display_ok => 0, nlabel => 'nf.registrations.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'nf-registrations-registered', display_ok => 0, nlabel => 'nf.registrations.registered.count', display_ok => 0, set => {
                key_values => [ { name => 'registered' }, { name => 'detected' } ],
                output_template => 'registered: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
                ]
            }
        },
        { label => 'nf-registrations-suspended', display_ok => 0, nlabel => 'nf.registrations.suspended.count', display_ok => 0, set => {
                key_values => [ { name => 'suspended' }, { name => 'detected' } ],
                output_template => 'suspended: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'detected' }
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

    $self->{maps_counters}->{registrations} = [
        { label => 'nf-registration-status', type => 2, critical_default => '%{status} =~ /suspended/i', set => {
                key_values => [ { name => 'status' }, { name => 'nfType' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'nf-registration-last', nlabel => 'nf.registration.last.seconds', set => {
                key_values => [ { name => 'registered_since_seconds' }, { name => 'registered_since_human' } ],
                output_template => 'last registered: %s',
                output_use => 'registered_since_human',
                perfdatas => [
                    { template => '%s', unit => 's', min => 0 }
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
        'filter-cluster-repository:s'  => { name => 'filter_cluster_repository' },
        'filter-registration-nftype:s' => { name => 'filter_registration_nftype' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $clusters = $options{custom}->query(queries => ['nf_data_layer_cluster_nodes{target_type="nrf"}']);
    my $nodes = $options{custom}->query(queries => ['nf_data_layer_cluster_nodes_status{target_type="nrf"}']);

    my $map_node_status = { 1 => 'running', 0 => 'notRunning' };
    my $map_registration_status = { 1 => 'registered', 0 => 'suspended' };

    $self->{global} = { clusters_detected => 0 };
    $self->{clusters} = {};

    foreach my $cluster (@$clusters) {
        next if (defined($self->{option_results}->{filter_cluster_repository}) && $self->{option_results}->{filter_cluster_repository} ne '' &&
            $cluster->{metric}->{repository} !~ /$self->{option_results}->{filter_cluster_repository}/);
 
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

    my $ctime = time();
    my $registration_infos = $options{custom}->query(queries => ['nf_registration_status{nfType!~"AUSF|AMF"}']);
    my $registration_ts = $options{custom}->query(queries => ['nf_registration_timestamp_seconds{nfType!~"AUSF|AMF"}']);

    $self->{global_registration} = { detected => 0, registered => 0, suspended => 0 };
    $self->{registrations} = {};
    foreach my $info (@$registration_infos) {
        next if (defined($self->{option_results}->{filter_registration_nftype}) && $self->{option_results}->{filter_registration_nftype} ne '' &&
            $info->{metric}->{nfType} !~ /$self->{option_results}->{filter_registration_nftype}/);

        $self->{registrations}->{ $info->{metric}->{nfType} } = {
            nfType => $info->{metric}->{nfType},
            status => $map_registration_status->{ $info->{value}->[1] }
        };
        $self->{global_registration}->{detected}++;
        $self->{global_registration}->{lc($map_registration_status->{ $info->{value}->[1] })}++;

        foreach my $ts (@$registration_ts) {
            next if ($info->{metric}->{nfType} ne $ts->{metric}->{nfType});

            $self->{registrations}->{ $info->{metric}->{nfType} }->{registered_since_seconds} = $ctime - $ts->{value}->[1];
            $self->{registrations}->{ $info->{metric}->{nfType} }->{registered_since_human} = centreon::plugins::misc::change_seconds(
                value => $self->{registrations}->{ $info->{metric}->{nfType} }->{registered_since_seconds}
            );
        }
    }
}

1;

__END__

=head1 MODE

Check network repository function.

=over 8

=item B<--filter-cluster-repository>

Filter clusters by repository name.

=item B<--filter-registration-nftype>

Filter registrations by nfType.

=item B<--unknown-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{repository}, %{node}

=item B<--warning-node-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{repository}, %{node}

=item B<--critical-node-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /notRunning/i').
You can use the following variables: %{status}, %{repository}, %{node}

=item B<--unknown-nf-registration-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{nfType}

=item B<--warning-nf-registration-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{nfType}

=item B<--critical-nf-registration-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /suspended/i').
You can use the following variables: %{status}, %{nfType}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'clusters-detected',
'cluster-nodes-detected', 'cluster-nodes-running', 'cluster-nodes-notrunning',
'nf-registration-last', 'nf-registrations-detected', 'nf-registrations-registered', 'nf-registrations-suspended'.

=back

=cut
