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

package network::athonet::epc::snmp::mode::aggregate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'traffic-in', nlabel => 'aggregate.traffic.in.bytespersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'traffic in: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'aggregate.traffic.out.bytespersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'traffic out: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'users-roaming-connected', nlabel => 'hss.users.roaming.connected.count', set => {
                key_values => [ { name => 'roaming_users' } ],
                output_template => 'roaming users connected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-authentication', nlabel => 'hss.requests.authentication.count', set => {
                key_values => [ { name => 'auth_req', diff => 1 } ],
                output_template => 'number of authentication requests: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'location-updates', nlabel => 'hss.location.updates.count', set => {
                key_values => [ { name => 'location_updates', diff => 1 } ],
                output_template => 'number of location updates: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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
    });

    return $self;
}

my $mapping = {
    traffic_in       => { oid => '.1.3.6.1.4.1.35805.10.2.99.5' }, # loadPktInGi
    traffic_out      => { oid => '.1.3.6.1.4.1.35805.10.2.99.6' }, # loadPktOutGi
    roaming_users    => { oid => '.1.3.6.1.4.1.35805.10.2.99.8' }, # hssRoamingUsers
    auth_req         => { oid => '.1.3.6.1.4.1.35805.10.2.99.9' }, # hssAuthenticationRequests
    location_updates => { oid => '.1.3.6.1.4.1.35805.10.2.99.10' } # hssLocationUpdates
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'athonet_epc_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
}

1;

__END__

=head1 MODE

Check aggregate statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='roaming'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out',
'users-roaming-connected', 'requests-authentication', 'location-updates'.

=back

=cut
