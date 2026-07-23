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

package cloud::zscaler::ztb::restapi::mode::gatewaycpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

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
        "gateway '%s' ",
        $options{instance_value}->{gatewayName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'gateways', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_gateway_output', cb_long_output => 'gateway_long_output', indent_long_output => '    ', message_multiple => 'All gateways are ok',
            group => [
                { name => 'cpu', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } }
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

    $self->{maps_counters}->{cpu} = [
          { label => 'cpu-utilization', nlabel => 'gateway.cpu.utilization.percentage', set => {
                key_values => [
                    { name => 'prct_used' }, { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }
                ],
                output_template => 'CPU average usage: %.2f %%',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;
                    
                    my $instances = [];
                    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
                        push @$instances, $self->{result_values}->{$_};
                    }

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => $instances,
                        value => sprintf('%.2f', $self->{result_values}->{prct_used}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
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
        'include-site-name:s'         => { name => 'include_site_name',  default => '' },
        'exclude-site-name:s'         => { name => 'exclude_site_name',  default => '' },
        'include-cluster-name:s'      => { name => 'include_cluster_name',  default => '' },
        'exclude-cluster-name:s'      => { name => 'exclude_cluster_name',  default => '' },
        'include-gateway-name:s'      => { name => 'include_gateway_name',  default => '' },
        'exclude-gateway-name:s'      => { name => 'exclude_gateway_name',  default => '' },
        'include-gateway-id:s'        => { name => 'include_gateway_id',  default => '' },
        'exclude-gateway-id:s'        => { name => 'exclude_gateway_id',  default => '' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(gatewayName)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { siteName => 1, clusterName => 1, gatewayName => 1 }
    );
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
            cpu => {
                gatewayName => $gw->{gw_name},
                clusterName => $gw->{cluster_name},
                siteName => $gw->{site_name}
            }
        };
        
        my $resource = $options{custom}->get_gateway_resource(gateway_id => $gw->{gw_id});
        if (defined($resource->{hourly_stat_last})) {
            $self->{gateways}->{ $gw->{gw_id} }->{cpu}->{prct_used} = $resource->{hourly_stat_last}->{cpu_used_avg};
        }

        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check gateway CPU.

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

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(gatewayName)')

=item B<--warning-gateways-detected>

Threshold.

=item B<--critical-gateways-detected>

Threshold.

=item B<--warning-cpu-utilization>

Threshold in percentage.

=item B<--critical-cpu-utilization>

Threshold in percentage.

=back

=cut
