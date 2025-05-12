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

package network::stormshield::api::mode::vpntunnels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'ike status: ' . $self->{result_values}->{ikeStatus};
}

sub custom_packets_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'packets %s: %s',
        $self->{result_values}->{label},
        $self->{result_values}->{value_absolute}
    );
}

sub custom_traffic_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{value_per_second}, network => 1);    
    return sprintf(
        'traffic %s: %s/s',
        $self->{result_values}->{label},
        $traffic_value . $traffic_unit
    );
}

sub custom_metric_calc {
    my ($self, %options) = @_;

    my ($checked, $total) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_$options{extra_options}->{instance_ref}_(.+)/) {
            $checked |= 1;
            my $new = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old = $options{old_datas}->{$_};

            $checked |= 2;
            my $diff = $new - $old;
            if ($diff < 0) {
                $total += $new;
            } else {
                $total += $diff;
            }
        }
    }

    if ($checked == 0) {
        $self->{error_msg} = 'skipped (no value)';
        return -10;
    }
    if ($checked == 1) {
        $self->{error_msg} = 'buffer creation';
        return -1;
    }

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{value_per_second} = $total / $options{delta_time};
    $self->{result_values}->{value_absolute} = $total;
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    return 0;
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;

    return "VPN tunnel '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'tunnels', type => 1, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All VPN tunnels are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tunnels-total', nlabel => 'vpn.tunnels.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total VPN tunnels: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnels} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{ikeStatus} =~ /connecting/',
            set => {
                key_values => [ { name => 'ikeStatus' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'tunnel-traffic-in', nlabel => 'vpn.tunnel.traffic.in.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { instance_ref => 'traffic_in', label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                threshold_use => 'value_per_second',
                perfdatas => [
                    { template => '%s', value => 'value_per_second', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tunnel-traffic-out', nlabel => 'vpn.tunnel.traffic.out.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { instance_ref => 'traffic_out', label_ref => 'traffic_out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                threshold_use => 'value_per_second',
                perfdatas => [
                    { template => '%s', value => 'value_per_second', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tunnel-packets-in', nlabel => 'vpn.tunnel.packets.in.count', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { instance_ref => 'packets_in', label_ref => 'in' },
                closure_custom_output => $self->can('custom_packets_output'),
                threshold_use => 'value_absolute',
                perfdatas => [
                    { template => '%s', value => 'value_absolute', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tunnel-packets-out', nlabel => 'vpn.tunnel.packets.out.count', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { instance_ref => 'packets_out', label_ref => 'out' },
                closure_custom_output => $self->can('custom_packets_output'),
                threshold_use => 'value_absolute',
                perfdatas => [
                    { template => '%s', value => 'value_absolute', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request(command => 'monitor getikesa');

    foreach my $entry (@{$result->{Result}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $entry->{rulename} !~ /$self->{option_results}->{filter_name}/);

        $self->{tunnels}->{ $entry->{rulename} } = {
            name      => $entry->{rulename},
            ikeStatus => $entry->{state}
        };
    }

    $result = $options{custom}->request(command => 'monitor getsa');

    foreach my $entry (@{$result->{Result}}) {
        next if (!defined($self->{tunnels}->{ $entry->{ikerulename} }));

        my $instance = $entry->{rulename};

        $self->{tunnels}->{ $entry->{ikerulename} }->{'traffic_in_' . $instance} = $entry->{bytesin} * 8;
        $self->{tunnels}->{ $entry->{ikerulename} }->{'traffic_out_' . $instance} = $entry->{bytesout} * 8;
        $self->{tunnels}->{ $entry->{ikerulename} }->{'packets_in_' . $instance} = $entry->{packetsin};
        $self->{tunnels}->{ $entry->{ikerulename} }->{'packets_out_' . $instance} = $entry->{packetsout};
    }
    
    $self->{cache_name} = 'stormshield_' . $options{custom}->get_connection_info() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '')
        );

    $self->{global} = { total => scalar(keys %{$self->{tunnels}}) };
}

1;

__END__

=head1 MODE

Check VPN tunnels.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='tunnels-total'

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{ikeStatus}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{ikeStatus} =~ /connecting/').
You can use the following variables: %{ikeStatus}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{ikeStatus}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tunnels-total', 'tunnel-traffic-in', 'tunnel-traffic-out',
'tunnel-packets-in', 'tunnel-packets-out'.

=back

=cut
