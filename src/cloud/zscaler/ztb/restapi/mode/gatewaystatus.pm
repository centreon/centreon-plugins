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

package cloud::zscaler::ztb::restapi::mode::gatewaystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "operational state: %s [desired state: %s]",
        $self->{result_values}->{operationalState},
        $self->{result_values}->{desiredState}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of gateways ';
}

sub gateway_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking gateway '%s' [site: %s, cluster: %s]",
        $options{instance_value}->{gatewayName},
        $options{instance_value}->{siteName},
        $options{instance_value}->{clusterName}
    );
}

sub prefix_gateway_output {
    my ($self, %options) = @_;

    return sprintf(
        "gateway '%s' [site: %s, cluster: %s] ",
        $options{instance_value}->{gatewayName},
        $options{instance_value}->{siteName},
        $options{instance_value}->{clusterName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'gateways', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_gateway_output', cb_long_output => 'gateway_long_output', indent_long_output => '    ', message_multiple => 'All gateways are ok',
            group => [
                { name => 'status', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
                { name => 'health', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
                { name => 'vrrp', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'gateways-detected', display_ok => 0, nlabel => 'gateways.detected.count',
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

    $self->{maps_counters}->{status} = [
        {
            label => 'gateway-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{desiredState} ne %{operationalState}',
            set => {
                key_values => [
                    { name => 'desiredState' }, { name => 'operationalState' },
                    { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    $self->{maps_counters}->{health} = [
        {
            label => 'gateway-health',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{healthColor} !~ /green/',
            set => {
                key_values => [
                    { name => 'healthColor' },
                    { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }
                ],
                output_template => 'health color: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{vrrp} = [
        {
            label => 'gateway-vrrp-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{vrrpState} =~ /fault/i',
            set => {
                key_values => [
                    { name => 'vrrpState' },
                    { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }
                ],
                output_template => 'VRRP state: %s',
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
        'include-site-name:s'         => { name => 'include_site_name',  default => '' },
        'exclude-site-name:s'         => { name => 'exclude_site_name',  default => '' },
        'include-cluster-name:s'      => { name => 'include_cluster_name',  default => '' },
        'exclude-cluster-name:s'      => { name => 'exclude_cluster_name',  default => '' },
        'include-gateway-name:s'      => { name => 'include_gateway_name',  default => '' },
        'exclude-gateway-name:s'      => { name => 'exclude_gateway_name',  default => '' },
        'include-gateway-id:s'        => { name => 'include_gateway_id',  default => '' },
        'exclude-gateway-id:s'        => { name => 'exclude_gateway_id',  default => '' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $gateways = $options{custom}->get_gateways();

    $self->{global} = { detected => 0 };
    $self->{gateways} = {};
    foreach my $gw (@$gateways) {
        next if is_excluded($gw->{site_name}, $self->{option_results}->{include_site_name}, $self->{option_results}->{exclude_site_name});
        next if is_excluded($gw->{cluster_name}, $self->{option_results}->{include_cluster_name}, $self->{option_results}->{exclude_cluster_name});
        next if is_excluded($gw->{gw_name}, $self->{option_results}->{include_gateway_name}, $self->{option_results}->{exclude_gateway_name});
        next if is_excluded($gw->{gw_id}, $self->{option_results}->{include_gateway_id}, $self->{option_results}->{exclude_gateway_id});

        $self->{gateways}->{ $gw->{gw_id} } = {
            gatewayName => $gw->{gw_name},
            clusterName => $gw->{cluster_name},
            siteName => $gw->{site_name},
            status => {
                gatewayName => $gw->{gw_name},
                clusterName => $gw->{cluster_name},
                siteName => $gw->{site_name},
                operationalState => $gw->{gw_operational_state},
                desiredState => $gw->{gw_desired_state}
            },
            health => {
                gatewayName => $gw->{gw_name},
                clusterName => $gw->{cluster_name},
                siteName => $gw->{site_name},
                healthColor => $gw->{gw_health_color}
            },
            vrrp => {
                gatewayName => $gw->{gw_name},
                clusterName => $gw->{cluster_name},
                siteName => $gw->{site_name},
                vrrpState => $gw->{gw_vrrp_state}
            }
        };

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check gateway status.

=over 8

=item B<--include-site-name>

Include site names (regexp).

=item B<--exclude-site-name>

Exclude site names (regexp).

=item B<--include-cluster-name>

Include cluster names (regexp).

=item B<--exclude-cluster-name>

Exclude cluster names (regexp).

=item B<--include-gateway-name>

Include gateway names (regexp).

=item B<--exclude-gateway-name>

Exclude gateway names (regexp).

=item B<--include-gateway-id>

Include gateway IDs (regexp).

=item B<--exclude-gateway-id>

Exclude gateway IDs (regexp).

=item B<--warning-gateways-detected>

Threshold.

=item B<--critical-gateways-detected>

Threshold.

=item B<--unknown-gateway-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{desiredState}, %{operationalState}

=item B<--warning-gateway-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{desiredState}, %{operationalState}

=item B<--critical-gateway-status>

Define the conditions to match for the status to be CRITICAL (default: '%{desiredState} ne %{operationalState}').
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{desiredState}, %{operationalState}

=item B<--unknown-gateway-health>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{healthColor}

=item B<--warning-gateway-health>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{healthColor}

=item B<--critical-gateway-health>

Define the conditions to match for the status to be CRITICAL (default: '%{healthColor} !~ /green/').
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{healthColor}

=item B<--unknown-gateway-vrrp-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{vrrpState}

=item B<--warning-gateway-vrrp-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{vrrpState}

=item B<--critical-gateway-vrrp-status>

Define the conditions to match for the status to be CRITICAL (default: '%{vrrpState} =~ /fault/i').
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{vrrpState}

=back

=cut
