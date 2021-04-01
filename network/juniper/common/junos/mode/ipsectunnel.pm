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

package network::juniper::common::junos::mode::ipsectunnel;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'ike state: ' . $self->{result_values}->{ike_state};
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'tunnel', type => 1, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All tunnels are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tunnels-total', nlabel => 'ipsec.tunnels.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Tunnels: %s',
                perfdatas => [
                    { label => 'total_tunnels', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnel} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'ike_state' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'tunnel-traffic-in', nlabel => 'ipsec.tunnel.traffic.in.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'),
                threshold_use => 'traffic_per_second',
                perfdatas => [
                    { value => 'traffic_per_second', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'tunnel-traffic-out', nlabel => 'ipsec.tunnel.traffic.out.bitspersecond', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'),
                threshold_use => 'traffic_per_second',
                perfdatas => [
                    { value => 'traffic_per_second', template => '%s',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub custom_traffic_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_second}, network => 1);    
    my $msg = sprintf("traffic %s: %s/s",
        $self->{result_values}->{label},
        $traffic_value . $traffic_unit
    );
    return $msg;
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    my ($checked, $total_bits) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_traffic_$options{extra_options}->{label_ref}_(\d+)/) {
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
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    return 0;
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;
    
    return "Tunnel '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{ike_state} eq "down"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_ike_state = { 1 => 'up', 2 => 'down' };

my $mapping = {
    jnxIkeTunMonState           => { oid => '.1.3.6.1.4.1.2636.3.52.1.1.2.1.6', map => $map_ike_state },
    jnxIkeTunMonRemoteIdValue   => { oid => '.1.3.6.1.4.1.2636.3.52.1.1.2.1.14' },
};
my $mapping2 = {
    jnxIpSecTunMonOutEncryptedBytes => { oid => '.1.3.6.1.4.1.2636.3.52.1.2.2.1.10' },
    jnxIpSecTunMonInDecryptedBytes  => { oid => '.1.3.6.1.4.1.2636.3.52.1.2.2.1.12' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{tunnel} = {};    
    my $request_oids = [
        { oid => $mapping->{jnxIkeTunMonState}->{oid} },
        { oid => $mapping->{jnxIkeTunMonRemoteIdValue}->{oid} },
    ];
    my $snmp_result = $options{snmp}->get_multiple_table(oids => $request_oids, return_type => 1, nothing_quit => 1);
    my $snmp_result2 = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping2->{jnxIpSecTunMonOutEncryptedBytes}->{oid} },
            { oid => $mapping2->{jnxIpSecTunMonInDecryptedBytes}->{oid} },
        ],
        return_type => 1
    );

    foreach (keys %$snmp_result) {
        next if (!/$mapping->{jnxIkeTunMonRemoteIdValue}->{oid}\.(\d+\.\d+)\.(\d+\.\d+\.\d+\.\d+)\.(\d+)/);
        my $instance = $1 . '.' . $2 . '.' . $3;
        my ($remote_type, $remote_addr, $tun_index) = ($1, $2, $3);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{jnxIkeTunMonRemoteIdValue} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{jnxIkeTunMonRemoteIdValue} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{tunnel}->{$instance} = {
            display => $result->{jnxIkeTunMonRemoteIdValue},
            ike_state => $result->{jnxIkeTunMonState},
        };

        foreach my $key (keys %$snmp_result2) {
            next if ($key !~ /^$mapping2->{jnxIpSecTunMonInDecryptedBytes}->{oid}\.$remote_type\.$remote_addr\.(\d+)/);

            my $instance2 = $remote_type . '.' . $remote_addr . '.' . $1;
            my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result2, instance => $instance2);

            $self->{tunnel}->{$instance}->{'traffic_in_' . $instance2} = $result2->{jnxIpSecTunMonInDecryptedBytes} * 8;
            $self->{tunnel}->{$instance}->{'traffic_out_' . $instance2} = $result2->{jnxIpSecTunMonOutEncryptedBytes} * 8;
        }
    }
    
    $self->{cache_name} = "juniper_junos_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{global} = { total => scalar(keys %{$self->{tunnel}}) };
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

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{ike_state}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{ike_state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{ike_state} eq "down"').
Can used special variables like: %{ike_state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tunnels-total', 'tunnel-traffic-in', 'tunnel-traffic-out'.

=back

=cut
