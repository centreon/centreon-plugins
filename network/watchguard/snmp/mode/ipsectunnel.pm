#
# Copyright 2020 Centreon (http://www.centreon.com/)
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
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnel} = [
        { label => 'tunnel-traffic-in', nlabel => 'ipsec.tunnel.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'wgIpsecTunnelInKbytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'tunnel-traffic-out', nlabel => 'ipsec.tunnel.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'wgIpsecTunnelOutKbytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    wgIpsecTunnelLocalAddr  => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.2' },
    wgIpsecTunnelPeerAddr   => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.3' },
};

my $oid_wgIpsecTunnelEntry = '.1.3.6.1.4.1.3097.6.5.1.2.1';
my $mapping2 = {
    wgIpsecTunnelInKbytes   => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.28' },
    wgIpsecTunnelOutKbytes  => { oid => '.1.3.6.1.4.1.3097.6.5.1.2.1.29' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{tunnel} = {};    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wgIpsecTunnelEntry,
        start => $mapping->{wgIpsecTunnelLocalAddr}->{oid},
        end => $mapping->{wgIpsecTunnelPeerAddr}->{oid},
        nothing_quit => 1
    );
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
    }
    
    if (scalar(keys %{$self->{tunnel}}) > 0) {
        $options{snmp}->load(oids => [
                map($_->{oid}, values(%$mapping2))
            ],
            instances => [keys %{$self->{tunnel}}], instance_regexp => '^(.*)$');
        $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
        foreach (keys %{$self->{tunnel}}) {
            my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);
            $result->{wgIpsecTunnelInKbytes} *= 1024 * 8;
            $result->{wgIpsecTunnelOutKbytes} *= 1024 * 8;
            $self->{tunnel}->{$_} = { %{$self->{tunnel}->{$_}}, %$result };
        }
    }

    $self->{global} = { total => scalar(keys %{$self->{tunnel}}) };

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
Can be: 'tunnels-total', 'tunnel-traffic-in', 'tunnel-traffic-out'.

=back

=cut
