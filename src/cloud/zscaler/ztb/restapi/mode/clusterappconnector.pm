#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::zscaler::ztb::restapi::mode::clusterappconnector;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of App Connectors ';
}

sub prefix_appconnector_output {
    my ($self, %options) = @_;

    return sprintf(
        "App Connector '%s' [cluster: %s] ",
        $options{instance_value}->{appConnectorName},
        $options{instance_value}->{clusterName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'appconnectors', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_appconnector_output', message_multiple => 'All App Connectors are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'appconnectors-detected', display_ok => 0, nlabel => 'appconnectors.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{appconnectors} = [
        {
            label => 'appconnector-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} ne "connected"',
            set => {
                key_values => [
                    { name => 'status' },
                    { name => 'clusterName' }, { name => 'appConnectorName' }
                ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'appconnector-running', nlabel => 'appconnector.running.count', set => {
                key_values => [
                    { name => 'running' }, { name => 'total' }, { name => 'clusterName' }, { name => 'appConnectorName' }
                ],
                output_template => 'running on gateways: %s',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;
                    
                    my $instances = [];
                    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
                        push @$instances, $self->{result_values}->{$_};
                    }

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => $instances,
                        value => $self->{result_values}->{running},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => $self->{result_values}->{total}
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
        'include-cluster-name:s'      => { name => 'include_cluster_name',  default => '' },
        'exclude-cluster-name:s'      => { name => 'exclude_cluster_name',  default => '' },
        'include-appconnector-name:s' => { name => 'include_appconnector_name',  default => '' },
        'exclude-appconnector-name:s' => { name => 'exclude_appconnector_name',  default => '' },
        'include-cluster-id:s'        => { name => 'include_cluster_id',  default => '' },
        'exclude-cluster-id:s'        => { name => 'exclude_cluster_id',  default => '' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(clusterName) %(appConnectorName)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { clusterName => 1, appConnectorName => 1 }
    );
}

sub search_appconnector_container_started {
    my ($self, %options) = @_;

    my ($running, $total) = (0, 0);
    foreach my $gw (@{$options{gateways}}) {
        next if ($options{cluster_id} ne $gw->{cluster_id});

        my $resource = $options{custom}->get_gateway_resource(gateway_id => $gw->{gw_id});
        if (defined($resource->{container_stats})) {
            foreach my $cstat (@{$resource->{container_stats}}) {
                if ($cstat->{cname} eq $options{name}) {
                    $running++;
                    last;
                }
            }
        }

        $total++;
    }

    return ($running, $total);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $gateways = $options{custom}->get_gateways();
    my $cluster = {};

    $self->{global} = { detected => 0 };
    $self->{appconnectors} = {};
    foreach my $gw (@$gateways) {
        next if (defined($cluster->{ $gw->{cluster_id} }));
        $cluster->{ $gw->{cluster_id} } = 1;

        next if is_excluded($gw->{cluster_name}, $self->{option_results}->{include_cluster_name}, $self->{option_results}->{exclude_cluster_name});
        next if is_excluded($gw->{cluster_id}, $self->{option_results}->{include_cluster_id}, $self->{option_results}->{exclude_cluster_id});

        my $config = $options{custom}->get_appconnector_config(cluster_id => $gw->{cluster_id});
        foreach (@$config) {
            next if is_excluded($_->{name}, $self->{option_results}->{include_appconnector_name}, $self->{option_results}->{exclude_appconnector_name});

            my ($running, $total) = $self->search_appconnector_container_started(
                custom => $options{custom},
                gateways => $gateways,
                name => $_->{name},
                cluster_id => $gw->{cluster_id}
            );

            $self->{appconnectors}->{ $gw->{cluster_id} . $_->{name} } = {
                clusterName      => $gw->{cluster_name},
                appConnectorName => $_->{name},
                status           => $_->{status},
                running          => $running,
                total            => $total
            };            

           $self->{global}->{detected}++;
        }
    }
}

1;

__END__

=head1 MODE

Check clusters App Connector.

=over 8

=item B<--include-cluster-name>

Include cluster names (regexp).

=item B<--exclude-cluster-name>

Exclude cluster names (regexp).

=item B<--include-appconnector-name>

Include App Connector names (regexp).

=item B<--exclude-appconnector-name>

Exclude App Connector names (regexp).

=item B<--include-cluster-id>

Include cluster IDs (regexp).

=item B<--exclude-cluster-id>

Exclude cluster IDs (regexp).

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(clusterName) %(appConnectorName)')

=item B<--unknown-appconnector-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{clusterName}, %{appConnectorName}, %{status}

=item B<--warning-appconnector-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{clusterName}, %{appConnectorName}, %{status}

=item B<--critical-appconnector-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} ne "connected"').
You can use the following variables: %{clusterName}, %{appConnectorName}, %{status}

=item B<--warning-appconnectors-detected>

Threshold.

=item B<--critical-appconnectors-detected>

Threshold.

=item B<--warning-appconnector-running>

Threshold.

=item B<--critical-appconnector-running>

Threshold.

=back

=cut
