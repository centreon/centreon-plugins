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

package network::meru::snmp::mode::wireless;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'accesspoints-online', nlabel => 'accesspoints.online.count', set => {
                key_values => [ { name => 'online_ap' } ],
                output_template => 'number of online access points: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'stations-wireless', nlabel => 'stations.wireless.count', set => {
                key_values => [ { name => 'wireless_stations' } ],
                output_template => 'number of wireless stations: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

my $mapping = {
    online_ap         => { oid => '.1.3.6.1.4.1.15983.1.1.3.1.13.9' }, # mwSystemGeneralTotalOnlineAps
    wireless_stations => { oid => '.1.3.6.1.4.1.15983.1.1.3.1.13.11' }  # mwSystemGeneralTotalWirelessStations
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
}

1;

__END__

=head1 MODE

Check wireless statistics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'accesspoints-online', 'stations-wireless'.

=back

=cut
