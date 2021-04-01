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

package network::ruckus::smartzone::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub system_long_output {
    my ($self, %options) = @_;

    return 'checking system ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 3, cb_long_output => 'system_long_output',
          indent_long_output => '    ',
            group => [
                { name => 'connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{connection} = [
        { label => 'connection-accesspoints', nlabel => 'system.connection.accesspoints.count', set => {
                key_values => [ { name => 'ap' } ],
                output_template => 'access points connections: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'connection-client-devices-authorized', nlabel => 'system.connection.client.devices.authorized.count', set => {
                key_values => [ { name => 'authorized_clients' } ],
                output_template => 'client devices authorized connections: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'system.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'system.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' }
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
    ap                    => { oid => '.1.3.6.1.4.1.25053.1.4.1.1.1.15.1' },  # ruckusSZSystemStatsNumAP
    authorized_clients    => { oid => '.1.3.6.1.4.1.25053.1.4.1.1.1.15.2' },  # ruckusSZSystemStatsNumSta
    traffic_in            => { oid => '.1.3.6.1.4.1.25053.1.4.1.1.1.15.6' }, # ruckusSZSystemStatsWLANTotalRxBytes
    traffic_out           => { oid => '.1.3.6.1.4.1.25053.1.4.1.1.1.15.9' }  # ruckusSZSystemStatsWLANTotalTxBytes
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    
    $self->{system}->{global} = {
        connection => {
            ap => $result->{ap},
            authorized_clients => $result->{authorized_clients}
        },
        traffic => {
            traffic_in => $result->{traffic_in} * 8,
            traffic_out => $result->{traffic_out} * 8
        }
    };

    $self->{cache_name} = 'ruckus_smartzone_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters_block}) ? md5_hex($self->{option_results}->{filter_counters_block}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out', 'connection-accesspoints',
'connection-client-devices-authorized'.

=back

=cut
