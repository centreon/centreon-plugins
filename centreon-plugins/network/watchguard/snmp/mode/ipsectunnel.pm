#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package network::watchguard::snmp::mode::ipsectunnel;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Socket;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Total ';
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;

    return "Tunnel '" . $options{instance_value}->{display} . "' ";
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    my ($checked, $total_bits) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        if (/^$self->{instance}_traffic_$options{extra_options}->{label_ref}_/) {
            $checked |= 1;
            my $new_bits = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_bits = $options{old_datas}->{$_};

            $checked |= 2;
            my $diff_bits = $new_bits - $old_bits;
            if ($diff_bits < 0) {
                $total_bits += $new_bits;
            } else {
                $total_bits += $diff_bits;
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

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic_per_second} = $total_bits / $options{delta_time};
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'tunnel', type => 1, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All tunnels are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tunnels-total', nlabel => 'ipsec.tunnels.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'tunnels: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnel} = [
        { label => 'tunnel-traffic-in', nlabel => 'ipsec.tunnel.traffic.in.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                output_use => 'traffic_per_second',
                threshold_use => 'traffic_per_second',
                perfdatas => [
                    { template => '%s', value => 'traffic_per_second', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'tunnel-traffic-out', nlabel => 'ipsec.tunnel.traffic.out.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                output_use => 'traffic_per_second', 
                threshold_use => 'traffic_per_second',
                perfdatas => [
                    { template => '%s', value => 'traffic_per_second', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
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

my $mapping = {
    wgIpsecTunnelLocalAddr  => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.2' },
    wgIpsecTunnelPeerAddr   => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.3' }
};

my $oid_wgIpsecTunnelEntry = '.1.3.6.1.4.1.3097.6.5.1.2.1';
my $mapping2 = {
    selector_remote_ip_one => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.20' }, # wgIpsecTunnelSelectorRemoteIPOne
    selector_remote_ip_two => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.21' }, # wgIpsecTunnelSelectorRemoteIPTwo
    selector_local_ip_one  => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.24' }, # wgIpsecTunnelSelectorLocalIPOne
    selector_local_ip_two  => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.25' }, # wgIpsecTunnelSelectorLocalIPTwo
    traffic_in             => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.28' }, # wgIpsecTunnelInKbytes
    traffic_out            => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.29' } # wgIpsecTunnelOutKbytes
};

# We could use the following OIDs for global counters :
# wgIpsecEndpointPairTotalInAccKbytes  - The total inbound IPSec traffic  - 1.3.6.1.4.1.3097.5.1.2.3
# wgIpsecEndpointPairTotalOutAccKbytes - The total outbound IPSec traffic - 1.3.6.1.4.1.3097.5.1.2.4
# But we would then not satisfy filter options, let's then compute these ourselves.

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wgIpsecTunnelEntry,
        start => $mapping->{wgIpsecTunnelLocalAddr}->{oid},
        end => $mapping->{wgIpsecTunnelPeerAddr}->{oid}
    );

    $self->{tunnel} = {};
    $self->{global} = { total => 0 };
    foreach (keys %$snmp_result) {
        next if (!/$mapping->{wgIpsecTunnelLocalAddr}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        my $name = $result->{wgIpsecTunnelLocalAddr} . ':' . $result->{wgIpsecTunnelPeerAddr};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{tunnel}->{$instance} = { display => $name };
        $self->{global}->{total}++;
    }

    if (scalar(keys %{$self->{tunnel}}) > 0) {
        $options{snmp}->load(oids => [
                map($_->{oid}, values(%$mapping2))
            ],
            instances => [keys %{$self->{tunnel}}],
            instance_regexp => '^(.*)$'
        );
        $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

        # tunnel ID moved... so we use the display
        # we can have tunnels with same display
        my @instances = keys %{$self->{tunnel}};
        foreach (@instances) {
            my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);
            $result->{traffic_in} = defined($result->{traffic_in}) ? $result->{traffic_in} * 1024 * 8 : 0;
            $result->{traffic_out} = defined($result->{traffic_out}) ? $result->{traffic_out} * 1024 * 8 : 0;

            my $uuid = $self->{tunnel}->{$_}->{display} . '_' . $result->{selector_local_ip_one} . '_' . $result->{selector_local_ip_two} . '_' .
                $result->{selector_remote_ip_one} . '_' . $result->{selector_remote_ip_two};
            $self->{tunnel}->{ $self->{tunnel}->{$_}->{display} } = { display => $self->{tunnel}->{$_}->{display} }
                if (!defined($self->{tunnel}->{ $self->{tunnel}->{$_}->{display} }));
            $self->{tunnel}->{ $self->{tunnel}->{$_}->{display} }->{'traffic_in_' . $uuid} = $result->{traffic_in};
            $self->{tunnel}->{ $self->{tunnel}->{$_}->{display} }->{'traffic_out_' . $uuid} = $result->{traffic_out};

            delete $self->{tunnel}->{$_};
        }
    }

    $self->{cache_name} = 'watchguard_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check ipsec tunnels.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='tunnels-total'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tunnels-total', 'tunnels-traffic-in', 'tunnels-traffic-out',
'tunnel-traffic-in', 'tunnel-traffic-out'.

=back

=cut
