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

package network::a10::ax::snmp::mode::globalstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'current-connections', nlabel => 'connections.current.count', set => {
                key_values => [ { name => 'current_connections' } ],
                output_template => 'Current Connections : %s',
                perfdatas => [
                    { label => 'current_connections', value => 'current_connections', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-connections', nlabel => 'connections.total.count', set => {
                key_values => [ { name => 'total_connections', diff => 1 } ],
                output_template => 'Total Connections : %s',
                perfdatas => [
                    { label => 'total_connections', value => 'total_connections', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'total-ssl-connections', nlabel => 'connections.ssl.total.count', set => {
                key_values => [ { name => 'total_ssl_connections', diff => 1 } ],
                output_template => 'Total SSL Connections : %s',
                perfdatas => [
                    { label => 'total_ssl_connections', value => 'total_ssl_connections', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $oid_axAppGlobalTotalCurrentConnections = '.1.3.6.1.4.1.22610.2.4.3.1.2.1.0';
    my $oid_axAppGlobalTotalNewConnections = '.1.3.6.1.4.1.22610.2.4.3.1.2.2.0';
    my $oid_axAppGlobalTotalSSLConnections = '.1.3.6.1.4.1.22610.2.4.3.1.2.6.0';
    my $result = $options{snmp}->get_leef(oids => [
            $oid_axAppGlobalTotalCurrentConnections, $oid_axAppGlobalTotalNewConnections,
            $oid_axAppGlobalTotalSSLConnections,
        ], 
        nothing_quit => 1);
    $self->{global} = { current_connections => $result->{$oid_axAppGlobalTotalCurrentConnections},
        total_connections => $result->{$oid_axAppGlobalTotalNewConnections},
        total_ssl_connections => $result->{$oid_axAppGlobalTotalSSLConnections},
    };
    
    $self->{cache_name} = "a10_ax_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check global statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^current-connections$'

=item B<--warning-*>

Threshold warning.
Can be: 'current-connections', 'total-connections'.

=item B<--critical-*>

Threshold critical.
Can be: 'current-connections', 'total-connections'.

=back

=cut
