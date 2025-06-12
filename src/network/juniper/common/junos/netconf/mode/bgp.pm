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

package network::juniper::common::junos::netconf::mode::bgp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_bgp_rib_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances_bgp_rib}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel},
        instances => $instances,
        value     => sprintf('%d', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0
    );
}

sub custom_bgp_peer_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances_bgp_peer}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel},
        instances => $instances,
        value     => sprintf('%d', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0
    );
}

sub custom_rib_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'send state: %s',
        $self->{result_values}->{sendState}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{peerState}
    );
}

sub bgp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking BGP peer [local address '%s', AS '%s'][peer address '%s', AS '%s']",
        $options{instance_value}->{localAddr},
        $options{instance_value}->{localAs},
        $options{instance_value}->{peerAddr},
        $options{instance_value}->{peerAs}
    );
}

sub prefix_bgp_output {
    my ($self, %options) = @_;

    return sprintf(
        "BGP peer [local address '%s', AS '%s'][peer address '%s', AS '%s'] ",
        $options{instance_value}->{localAddr},
        $options{instance_value}->{localAs},
        $options{instance_value}->{peerAddr},
        $options{instance_value}->{peerAs}
    );
}

sub prefix_rib_output {
    my ($self, %options) = @_;

    return sprintf(
        "RIB '%s' ",
        $options{instance_value}->{ribName}
    );
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic ';
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of BGP peers ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name               => 'bgp', type => 3, cb_prefix_output => 'prefix_bgp_output', cb_long_output => 'bgp_long_output',
          indent_long_output => '    ', message_multiple => 'All BGP peers are ok',
          group              => [
              { name => 'status', type => 0, skipped_code => { -10 => 1 } },
              { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } },
              { name             => 'ribs', display_long => 1, cb_prefix_output => 'prefix_rib_output',
                message_multiple => 'All BGP ribs are ok', type => 1 }
          ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'bgp-peer-detected', display_ok => 0, nlabel => 'bgp.peers.detected.count', set => {
            key_values      => [ { name => 'detected' } ],
            output_template => 'detected: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{peerState} !~ /established/i',
            set              => {
                key_values                     => [
                    { name => 'localAddr' }, { name => 'localAs' }, { name => 'peerAddr' }, { name => 'peerAs' },
                    { name => 'peerState' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'bgp-peer-traffic-in', nlabel => 'bgp.peer.traffic.in.bytes', set => {
            key_values              => [ { name => 'inBytes', diff => 1 }, { name => 'localAddr' }, { name => 'localAs' }, { name => 'peerAddr' }, { name => 'peerAs' } ],
            output_template         => 'in: %s %s',
            output_change_bytes     => 1,
            closure_custom_perfdata => $self->can('custom_bgp_peer_perfdata')
        }
        },
        { label => 'bgp-peer-traffic-out', nlabel => 'bgp.peer.traffic.out.bytes', set => {
            key_values              => [ { name => 'outBytes', diff => 1 }, { name => 'localAddr' }, { name => 'localAs' }, { name => 'peerAddr' }, { name => 'peerAs' } ],
            output_template         => 'out: %s %s',
            output_change_bytes     => 1,
            closure_custom_perfdata => $self->can('custom_bgp_peer_perfdata')
        }
        }
    ];

    $self->{maps_counters}->{ribs} = [
        {
            label => 'rib-status',
            type  => 2,
            set   => {
                key_values                     => [
                    { name => 'localAddr' }, { name => 'localAs' }, { name => 'peerAddr' }, { name => 'peerAs' },
                    { name => 'ribName' }, { name => 'sendState' }
                ],
                closure_custom_output          => $self->can('custom_rib_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'bgp-peer-rib-prefixes-active', nlabel => 'bgp.peer.rib.prefixes.active.count', set => {
            key_values              => [
                { name => 'activePrefix' }, { name => 'localAddr' }, { name => 'localAs' }, { name => 'peerAddr' }, { name => 'peerAs' },
                { name => 'ribName' }
            ],
            output_template         => 'prefixes active: %d',
            closure_custom_perfdata => $self->can('custom_bgp_rib_perfdata')
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-snmp-index:s'                  => { name => 'filter_snmp_index' },
        'filter-local-address:s'               => { name => 'filter_local_address' },
        'filter-peer-address:s'                => { name => 'filter_peer_address' },
        'filter-rib-name:s'                    => { name => 'filter_rib_name' },
        'custom-perfdata-instances-bgp-peer:s' => { name => 'custom_perfdata_instances_bgp_peer' },
        'custom-perfdata-instances-bgp-rib:s'  => { name => 'custom_perfdata_instances_bgp_rib' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances_bgp_peer}) || $self->{option_results}->{custom_perfdata_instances_bgp_peer} eq '') {
        $self->{option_results}->{custom_perfdata_instances_bgp_peer} = '%(localAddr) %(peerAddr)';
    }

    $self->{custom_perfdata_instances_bgp_peer} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances-bgp-peer',
        instances   => $self->{option_results}->{custom_perfdata_instances_bgp_peer},
        labels      => { localAddr => 1, localAs => 1, peerAddr => 1, peerAs => 1 }
    );

    if (!defined($self->{option_results}->{custom_perfdata_instances_bgp_rib}) || $self->{option_results}->{custom_perfdata_instances_bgp_rib} eq '') {
        $self->{option_results}->{custom_perfdata_instances_bgp_rib} = '%(localAddr) %(peerAddr) %(ribName)';
    }

    $self->{custom_perfdata_instances_bgp_rib} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances-bgp-rib',
        instances   => $self->{option_results}->{custom_perfdata_instances_bgp_rib},
        labels      => { localAddr => 1, localAs => 1, peerAddr => 1, peerAs => 1, ribName => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_bgp_infos();

    $self->{global} = { detected => 0 };
    $self->{bgp} = {};
    foreach my $item (@$result) {
        next if (defined($self->{option_results}->{filter_snmp_index}) && $self->{option_results}->{filter_snmp_index} ne '' &&
                 $item->{snmpIndex} !~ /$self->{option_results}->{filter_snmp_index}/);
        next if (defined($self->{option_results}->{filter_local_address}) && $self->{option_results}->{filter_local_address} ne '' &&
                 $item->{localAddr} !~ /$self->{option_results}->{filter_local_address}/);
        next if (defined($self->{option_results}->{filter_peer_address}) && $self->{option_results}->{filter_peer_address} ne '' &&
                 $item->{peerAddr} !~ /$self->{option_results}->{filter_peer_address}/);

        $self->{bgp}->{ $item->{snmpIndex} } = {
            localAddr => $item->{localAddr},
            localAs   => $item->{localAs},
            peerAddr  => $item->{peerAddr},
            peerAs    => $item->{peerAs},
            status    => {
                localAddr => $item->{localAddr},
                localAs   => $item->{localAs},
                peerAddr  => $item->{peerAddr},
                peerAs    => $item->{peerAs},
                peerState => $item->{peerState}
            },
            traffic   => {
                localAddr => $item->{localAddr},
                localAs   => $item->{localAs},
                peerAddr  => $item->{peerAddr},
                peerAs    => $item->{peerAs},
                inBytes   => $item->{inBytes},
                outBytes  => $item->{outBytes}
            },
            ribs      => {}
        };

        foreach (@{$item->{ribs}}) {
            next if (defined($self->{option_results}->{filter_rib_name}) && $self->{option_results}->{filter_rib_name} ne '' &&
                     $_->{ribName} !~ /$self->{option_results}->{filter_rib_name}/);

            $self->{bgp}->{ $item->{snmpIndex} }->{ribs}->{ $_->{ribName} } = {
                localAddr => $item->{localAddr},
                localAs   => $item->{localAs},
                peerAddr  => $item->{peerAddr},
                peerAs    => $item->{peerAs},
                %$_
            };
        }

        $self->{global}->{detected}++;
    }

    $self->{cache_name} = 'juniper_api_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
                          md5_hex(
                              (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
                              (defined($self->{option_results}->{filter_snmp_index}) ? $self->{option_results}->{filter_snmp_index} : '') . '_' .
                              (defined($self->{option_results}->{filter_local_address}) ? $self->{option_results}->{filter_local_address} : '') . '_' .
                              (defined($self->{option_results}->{filter_peer_address}) ? $self->{option_results}->{filter_peer_address} : '') . '_' .
                              (defined($self->{option_results}->{filter_rib_name}) ? $self->{option_results}->{filter_rib_name} : '')
                          );
}

1;

__END__

=head1 MODE

Check BGP peers.

=over 8

=item B<--filter-snmp-index>

Filter BGP peer by SNMP index.

=item B<--filter-local-address>

Filter BGP peer by local address.

=item B<--filter-peer-address>

Filter BGP peer by peer address.

=item B<--filter-rib-name>

Filter BGP RIB by RIB name.

=item B<--custom-perfdata-instances-bgp-peer>

Define performance data instances (default: '%(localAddr) %(peerAddr)')

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{localAddr}, %{localAs}, %{peerAddr}, %{peerAs}, %{peerState}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{localAddr}, %{localAs}, %{peerAddr}, %{peerAs}, %{peerState}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{peerState} !~ /established/i').
You can use the following variables: %{localAddr}, %{localAs}, %{peerAddr}, %{peerAs}, %{peerState}

=item B<--unknown-rib-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{localAddr}, %{localAs}, %{peerAddr}, %{peerAs}, %{peerState}, %{ribName}, %{sendState}

=item B<--warning-rib-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{localAddr}, %{localAs}, %{peerAddr}, %{peerAs}, %{peerState}, %{ribName}, %{sendState}

=item B<--critical-rib-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{localAddr}, %{localAs}, %{peerAddr}, %{peerAs}, %{peerState}, %{ribName}, %{sendState}

=item B<--warning-bgp-peer-detected>

Warning threshold for number of BGP peers detected.

=item B<--critical-bgp-peer-detected>

Critical threshold for number of BGP peers detected.

=item B<--warning-bgp-peer-traffic-in>

Warning threshold for BGP peer traffic in.

=item B<--critical-bgp-peer-traffic-in>

Critical threshold for BGP peer traffic in.

=item B<--warning-bgp-peer-traffic-out>

Warning threshold for BGP peer traffic out.

=item B<--critical-bgp-peer-traffic-out>

Critical threshold for BGP peer traffic out.

=back

=cut
