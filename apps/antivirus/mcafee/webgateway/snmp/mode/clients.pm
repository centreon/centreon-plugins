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

package apps::antivirus::mcafee::webgateway::snmp::mode::clients;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'clients', nlabel => 'clients.connected.count', set => {
                key_values => [ { name => 'stClientCount' } ],
                output_template => 'Connected clients: %d',
                perfdatas => [
                    { label => 'connected_clients', template => '%d',
                      min => 0, unit => 'clients' }
                ]
            }
        },
        { label => 'sockets', nlabel => 'sockets.connected.count', set => {
                key_values => [ { name => 'stConnectedSockets' } ],
                output_template => 'Open network sockets: %d',
                perfdatas => [
                    { label => 'open_sockets', template => '%d',
                      min => 0, unit => 'sockets' }
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

my $oid_stClientCount = '.1.3.6.1.4.1.1230.2.7.2.5.2.0';
my $oid_stConnectedSockets = '.1.3.6.1.4.1.1230.2.7.2.5.3.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(
        oids => [ $oid_stClientCount, $oid_stConnectedSockets ], 
        nothing_quit => 1
    );

    $self->{global} = {
        stClientCount => $results->{$oid_stClientCount},
        stConnectedSockets => $results->{$oid_stConnectedSockets},
    };
}

1;

__END__

=head1 MODE

Check connected clients and open network sockets.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='clients')

=item B<--warning-*>

Threshold warning.
Can be: 'clients', 'sockets'.

=item B<--critical-*>

Threshold critical.
Can be: 'clients', 'sockets'.

=back

=cut
