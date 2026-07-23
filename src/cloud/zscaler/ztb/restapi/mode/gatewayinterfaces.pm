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

package cloud::zscaler::ztb::restapi::mode::gatewayinterfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::SHA qw/sha256_hex/;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'counter') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/bitspersecond/bits/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => 'b',
            instances => $instances,
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => $instances,
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{traffic_unit} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_counter}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{traffic_per_seconds} = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} } - $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} }) / $options{delta_time};
    $self->{result_values}->{traffic_counter} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };

    $self->{result_values}->{traffic_per_seconds} = sprintf('%d', $self->{result_values}->{traffic_per_seconds});

    if (defined($options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}}) &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} ne '' &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} > 0) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{gatewayName} = $options{new_datas}->{$self->{instance} . '_gatewayName'};
    $self->{result_values}->{clusterName} = $options{new_datas}->{$self->{instance} . '_clusterName'};
    $self->{result_values}->{siteName} = $options{new_datas}->{$self->{instance} . '_siteName'};
    $self->{result_values}->{interfaceName} = $options{new_datas}->{$self->{instance} . '_interfaceName'};
    return 0;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);
    return sprintf(
        'traffic %s: %s/s (%s)',
        $self->{result_values}->{label}, $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_interface_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "operational state: %s [admin state: %s]",
        $self->{result_values}->{operationalState},
        $self->{result_values}->{adminState}
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
        "gateway '%s' ",
        $options{instance_value}->{gatewayName}
    );
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "interface '%s' ",
        $options{instance_value}->{interfaceName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'gateways', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_gateway_output', cb_long_output => 'gateway_long_output', indent_long_output => '    ', message_multiple => 'All gateways are ok',
            group => [
                { name => 'interfaces', type => COUNTER_MULTIPLE_SUBINSTANCE, cb_prefix_output => 'prefix_interface_output', skipped_code => { NO_VALUE() => 1 } }
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

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'interface-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{adminState} =~ /up/ and %{operationalState} !~ /up/',
            set => {
                key_values => [
                    { name => 'adminState' }, { name => 'operationalState' },
                    { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }, { name => 'interfaceName' }
                ],
                closure_custom_output => $self->can('custom_interface_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'interface-traffic-in', nlabel => 'gateway.interface.traffic.in.bitspersecond', set => {
                key_values => [
                    { name => 'in', diff => 1 }, { name => 'speed_in' },
                    { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }, { name => 'interfaceName' }
                ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'interface-traffic-out', nlabel => 'gateway.interface.traffic.out.bitspersecond', set => {
                key_values => [
                    { name => 'out', diff => 1 }, { name => 'speed_out' },
                    { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }, { name => 'interfaceName' }
                ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'interface-jitter', nlabel => 'gateway.interface.jitter.milliseconds', set => {
                key_values => [
                    { name => 'jitter' }, { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }, { name => 'interfaceName' }
                ],
                output_template => 'jitter: %s ms',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;
                    
                    my $instances = [];
                    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
                        push @$instances, $self->{result_values}->{$_};
                    }

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'ms',
                        instances => $instances,
                        value => $self->{result_values}->{jitter},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'interface-latency', nlabel => 'gateway.interface.latency.milliseconds', set => {
                key_values => [
                    { name => 'latency' }, { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }, { name => 'interfaceName' }
                ],
                output_template => 'latency: %s ms',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;
                    
                    my $instances = [];
                    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
                        push @$instances, $self->{result_values}->{$_};
                    }

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'ms',
                        instances => $instances,
                        value => $self->{result_values}->{latency},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'interface-loss', nlabel => 'gateway.interface.loss.percentage', set => {
                key_values => [
                    { name => 'loss' }, { name => 'gatewayName' }, { name => 'clusterName' }, { name => 'siteName' }, { name => 'interfaceName' }
                ],
                output_template => 'loss: %.2f %%',
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
                        value => sprintf('%.2f', $self->{result_values}->{loss}),
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
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
        'include-interface-name:s'    => { name => 'include_interface_name',  default => '' },
        'exclude-interface-name:s'    => { name => 'exclude_interface_name',  default => '' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' },
        'traffic-unit:s'              => { name => 'traffic_unit', default => 'percent_delta' },
        'speed:s'                     => { name => 'speed' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(gatewayName) %(interfaceName)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { siteName => 1, clusterName => 1, gatewayName => 1, interfaceName => 1 }
    );

    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
        if ($self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
            $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also)");
            $self->{output}->option_exit();
        } else {
            $self->{option_results}->{speed} *= 1000000;
        }
    }

    $self->{option_results}->{traffic_unit} = 'percent_delta'
        if (!defined($self->{option_results}->{traffic_unit}) ||
            $self->{option_results}->{traffic_unit} eq '' ||
            $self->{option_results}->{traffic_unit} eq '%');
    if ($self->{option_results}->{traffic_unit} !~ /^(?:percent|percent_delta|bps|counter)$/) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --traffic-unit');
        $self->{output}->option_exit();
    }
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
            interfaces => {}
        };

        my $interfaces = $options{custom}->get_gateway_interfaces(gateway_id => $gw->{gw_id});
        my $resource = $options{custom}->get_gateway_resource(gateway_id => $gw->{gw_id});
        foreach my $int (@$interfaces) {
            next if is_excluded($int->{name}, $self->{option_results}->{include_interface_name}, $self->{option_results}->{exclude_interface_name});

            $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} } = {
                gatewayName      => $gw->{gw_name},
                clusterName      => $gw->{cluster_name},
                siteName         => $gw->{site_name},
                interfaceName    => $int->{name},
                adminState       => $int->{admin_state},
                operationalState => $int->{operational_state}
            };

            if (defined($int->{if_stats}->{rx_bytes})) {
                # format: 1G
                my $speed = centreon::plugins::misc::convert_bytes_ng(value => $int->{if_stats}->{if_speed});
                $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} }->{in} = $int->{if_stats}->{rx_bytes} * 8;
                $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} }->{out} = $int->{if_stats}->{tx_bytes} * 8;
                $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} }->{speed_in} = defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' ? $self->{option_results}->{speed} : $speed;
                $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} }->{speed_out} = defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '' ? $self->{option_results}->{speed} : $speed;
            }

            if (defined($resource->{wanmon_avg_values_last}->{interfaces})) {
                foreach (@{$resource->{wanmon_avg_values_last}->{interfaces}}) {
                    if ($int->{name} eq $_->{wan_intf_name}) {
                        $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} }->{loss} = $_->{loss};
                        $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} }->{jitter} = $_->{jitter};
                        $self->{gateways}->{ $gw->{gw_id} }->{interfaces}->{ $int->{name} }->{latency} = $_->{latency};
                        last;
                    }
                }
            }
        }

        $self->{global}->{detected}++;
    }

    $self->{cache_name} = 'zscaler_ztb_' . $options{custom}->get_connection_info()  . '_' . $self->{mode} . '_' .
        sha256_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{include_site_name}) ? $self->{option_results}->{include_site_name} : '') . '_' .
            (defined($self->{option_results}->{exclude_site_name}) ? $self->{option_results}->{exclude_site_name} : '') . '_' .
            (defined($self->{option_results}->{include_cluster_name}) ? $self->{option_results}->{include_cluster_name} : '') . '_' .
            (defined($self->{option_results}->{exclude_cluster_name}) ? $self->{option_results}->{exclude_cluster_name} : '') . '_' .
            (defined($self->{option_results}->{include_gateway_name}) ? $self->{option_results}->{include_gateway_name} : '') . '_' .
            (defined($self->{option_results}->{exclude_gateway_name}) ? $self->{option_results}->{exclude_gateway_name} : '') . '_' .
            (defined($self->{option_results}->{include_interface_name}) ? $self->{option_results}->{include_interface_name} : '') . '_' .
            (defined($self->{option_results}->{exclude_interface_name}) ? $self->{option_results}->{exclude_interface_name} : '')
        );
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['siteName', 'clusterName', 'gatewayName', 'interfaceName', 'adminState', 'operationalState']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $gateways = $options{custom}->get_gateways();
    foreach my $gw (@$gateways) {
        next if is_excluded($gw->{site_name}, $self->{option_results}->{include_site_name}, $self->{option_results}->{exclude_site_name});
        next if is_excluded($gw->{cluster_name}, $self->{option_results}->{include_cluster_name}, $self->{option_results}->{exclude_cluster_name});
        next if is_excluded($gw->{gw_name}, $self->{option_results}->{include_gateway_name}, $self->{option_results}->{exclude_gateway_name});
        next if is_excluded($gw->{gw_id}, $self->{option_results}->{include_gateway_id}, $self->{option_results}->{exclude_gateway_id});

        my $interfaces = $options{custom}->get_gateway_interfaces(gateway_id => $gw->{gw_id});
        foreach my $int (@$interfaces) {
            next if is_excluded($int->{name}, $self->{option_results}->{include_interface_name}, $self->{option_results}->{exclude_interface_name});

            $self->{output}->add_disco_entry(
                gatewayName      => $gw->{gw_name},
                clusterName      => $gw->{cluster_name},
                siteName         => $gw->{site_name},
                interfaceName    => $int->{name},
                adminState       => $int->{admin_state},
                operationalState => $int->{operational_state}
            );
        }
    }
}

1;

__END__

=head1 MODE

Check gateway interfaces.

=over 8

=item B<--include-interface-name>

Include interface names (regexp).

=item B<--exclude-interface-name>

Exclude interface names (regexp).

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

Define perfdatas instance (default: '%(gatewayName) %(interfaceName)')

=item B<--traffic-unit>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--speed>

Set interface speed (in Mb).

=item B<--unknown-gateway-interface-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{interfaceName}, %{adminState}, %{operationalState}

=item B<--warning-gateway-interface-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{interfaceName}, %{adminState}, %{operationalState}

=item B<--critical-gateway-interface-status>

Define the conditions to match for the status to be CRITICAL (default: '%{adminState} =~ /up/ and %{operationalState} !~ /up/').
You can use the following variables: %{siteName}, %{clusterName}, %{gatewayName}, %{interfaceName}, %{adminState}, %{operationalState}

=item B<--warning-gateways-detected>

Threshold.

=item B<--critical-gateways-detected>

Threshold.

=item B<--warning-interface-traffic-in>

Threshold.

=item B<--critical-interface-traffic-in>

Threshold.

=item B<--warning-interface-traffic-out>

Threshold.

=item B<--critical-interface-traffic-out>

Threshold.

=item B<--warning-interface-jitter>

Threshold.

=item B<--critical-interface-jitter>

Threshold.

=item B<--warning-interface-latency>

Threshold.

=item B<--critical-interface-latency>

Threshold.

=item B<--warning-interface-loss>

Threshold.

=item B<--critical-interface-loss>

Threshold.

=back

=cut
