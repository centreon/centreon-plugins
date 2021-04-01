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

package network::watchguard::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'connections', nlabel => 'system.connections.current.count', set => {
                key_values => [ { name => 'connections' } ],
                output_template => 'Current connections: %s',
                perfdatas => [
                    { label => 'current_connections', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'in-traffic', nlabel => 'system.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in_traffic', per_second => 1 } ],
                output_template => 'Traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%s', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'out-traffic', nlabel => 'system.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out_traffic', per_second => 1 } ],
                output_template => 'Traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%s', min => 0, unit => 'b/s' }
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

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => 'Need to use SNMP v2c or v3.');
        $self->{output}->option_exit();
    }

    my $oid_wgSystemTotalSendBytes = '.1.3.6.1.4.1.3097.6.3.8.0';
    my $oid_wgSystemTotalRecvBytes = '.1.3.6.1.4.1.3097.6.3.9.0';
    my $oid_wgSystemCurrActiveConns = '.1.3.6.1.4.1.3097.6.3.80.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_wgSystemTotalSendBytes, $oid_wgSystemTotalRecvBytes, $oid_wgSystemCurrActiveConns
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        out_traffic => $snmp_result->{$oid_wgSystemTotalSendBytes} * 8,
        in_traffic => $snmp_result->{$oid_wgSystemTotalRecvBytes} * 8,
        connections => $snmp_result->{$oid_wgSystemCurrActiveConns}
    };

    $self->{cache_name} = 'watchguard_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^connections$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'in-traffic', 'out-traffic', 'connections'.

=back

=cut
