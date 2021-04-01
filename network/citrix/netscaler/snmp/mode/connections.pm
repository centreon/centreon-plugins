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

package network::citrix::netscaler::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'connections.server.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active Server TCP connections: %s',
                perfdatas => [
                    { label => 'active_server', template => '%s', unit => 'con', min => 0 }
                ]
            }
        },
        { label => 'server', nlabel => 'connections.server.count', set => {
                key_values => [ { name => 'server' } ],
                output_template => 'Server TCP connections: %s',
                perfdatas => [
                    { label => 'server', template => '%s', unit => 'con', min => 0 }
                ]
            }
        },
        { label => 'client', nlabel => 'connections.client.count', set => {
                key_values => [ { name => 'client' } ],
                output_template => 'Client TCP connections: %s',
                perfdatas => [
                    { label => 'client', template => '%s',  unit => 'con', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { client => 0, server => 0, active => 0 }; 
    my $oid_tcpCurServerConn = '.1.3.6.1.4.1.5951.4.1.1.46.1.0';
    my $oid_tcpCurClientConn = '.1.3.6.1.4.1.5951.4.1.1.46.2.0'; 
    my $oid_tcpActiveServerConn = '.1.3.6.1.4.1.5951.4.1.1.46.8.0';
    my $result = $options{snmp}->get_leef(oids => [$oid_tcpCurServerConn, $oid_tcpCurClientConn, $oid_tcpActiveServerConn ], nothing_quit => 1);
    $self->{global}->{client} = $result->{$oid_tcpCurClientConn};
    $self->{global}->{server} = $result->{$oid_tcpCurServerConn};
    $self->{global}->{active} = $result->{$oid_tcpActiveServerConn};
}

1;

__END__

=head1 MODE

Check connections usage (Client, Server, ActiveServer) (NS-ROOT-MIBv2).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'server', 'active', 'client'.

=item B<--critical-*>

Threshold critical.
Can be: 'server', 'active', 'client'.

=back

=cut
