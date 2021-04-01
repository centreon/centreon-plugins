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

package network::stormshield::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'udp', set => {
                key_values => [ { name => 'udp', per_second => 1 } ],
                output_template => 'UDP : %d connections/s',
                perfdatas => [
                    { label => 'udp', template => '%d', min => 0, unit => 'con' }
                ]
            }
        },
        { label => 'tcp', set => {
                key_values => [ { name => 'tcp', per_second => 1 } ],
                output_template => 'TCP : %d connections/s',
                perfdatas => [
                    { label => 'tcp', template => '%d', min => 0, unit => 'con' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{cache_name} = "fw_stormshield_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . md5_hex('all');

    my $oid_ntqASQStatsStatefulUdpConn = '.1.3.6.1.4.1.11256.1.12.1.33.0';
    my $oid_ntqASQStatsStatefulTcpConn = '.1.3.6.1.4.1.11256.1.12.1.23.0';

    my $result = $options{snmp}->get_leef(oids => [ $oid_ntqASQStatsStatefulUdpConn, $oid_ntqASQStatsStatefulTcpConn ],
                                          nothing_quit => 1);
    $self->{global} = {
        udp => $result->{$oid_ntqASQStatsStatefulUdpConn},
        tcp => $result->{$oid_ntqASQStatsStatefulTcpConn},
    };
}

1;

__END__

=head1 MODE

Check connections setup rate on Stormshield Firewall equipments.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'tcp', 'udp'

=item B<--critical-*>

Threshold critical.
Can be: 'tcp', 'udp'

=back

=cut
