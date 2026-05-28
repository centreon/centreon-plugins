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

package network::paloalto::api::mode::ipsec;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(is_excluded);

sub prefix_tunnel_output {
    my ($self, %options) = @_;
    return sprintf("tunnel '%s' ", $options{instance_value}->{name});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Tunnels ' },
        { name => 'tunnels', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All tunnels are ok' }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'tunnels-count',
            nlabel => 'tunnels.count',
            set => {
                key_values => [ { name => 'tunnels_count' } ],
                output_template => 'count: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnels} = [
        {
            label  => 'remain-time',
            nlabel => 'tunnel.remain.seconds',
            set => {
                key_values      => [ { name => 'remain' }, { name => 'name' } ],
                output_template => 'remain: %s seconds',
                perfdatas => [
                    { template => '%s', unit => 's', min => 0,
                      label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        {
            label => 'encryption',
            type  => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'enc' }, { name => 'name' } ],
                output_template => 'encryption: %s'
            }
        },
        {
            label => 'gateway',
            type  => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'gateway' }, { name => 'name' } ],
                output_template => 'gateway: %s'
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-tunnel-name:s'  => { name => 'include_tunnel_name',  default => '' },
        'exclude-tunnel-name:s'  => { name => 'exclude_tunnel_name',  default => '' },
        'include-gateway-name:s' => { name => 'include_gateway_name', default => '' },
        'exclude-gateway-name:s' => { name => 'exclude_gateway_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<show><vpn><ipsec-sa></ipsec-sa></vpn></show>',
        ForceArray => ['entry']
    );

    $self->{tunnels} = {};
    $self->{global} = { tunnels_count => 0 };

    $self->{output}->option_exit(short_msg => "No matching device !")
        unless ref $result->{entries} eq 'HASH';

    foreach my $entry (@{$result->{entries}->{entry}}) {
        my $name = $entry->{name} // '';
        my $gateway = $entry->{gateway} // '';

        next if is_excluded($name, $self->{option_results}->{include_tunnel_name}, $self->{option_results}->{exclude_tunnel_name}, output => $self->{output}) ||
                is_excluded($gateway, $self->{option_results}->{include_gateway_name}, $self->{option_results}->{exclude_gateway_name}, output => $self->{output});

        $self->{tunnels}->{$name} = {
            name    => $name,
            gateway => $gateway,
            enc     => $entry->{enc} // 'Unknown',
            remain  => $entry->{remain} // 0,
            proto   => $entry->{proto} // 'Unknown'
        };
        $self->{global}->{tunnels_count}++;
    }
}

1;

__END__

=head1 MODE

Check Palo Alto IPsec VPN tunnels status and lifetime.

=over 8

=item B<--include-tunnel-name>

Include tunnel names (regexp).

=item B<--exclude-tunnel-name>

Exclude tunnel names (regexp).

=item B<--include-gateway-name>

Include gateway names (regexp).

=item B<--exclude-gateway-name>

Exclude gateway names (regexp).

=item B<--warning-tunnels-count>

Warning threshold for tunnels count.

=item B<--critical-tunnels-count>

Critical threshold for tunnels count.

=item B<--warning-remain-time>

Warning threshold for tunnel remain time in seconds.

=item B<--critical-remain-time>

Critical threshold for tunnel remain time in seconds.

=back

=cut
