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

package network::ruckus::scg::snmp::mode::systemstats;

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
        { label => 'aps-count', set => {
                key_values => [ { name => 'ruckusSystemStatsNumAP' } ],
                output_template => 'APs count: %s',
                perfdatas => [
                    { label => 'aps_count', template => '%s', unit => 'aps', min => 0 },
                ],
            }
        },
        { label => 'users-count', set => {
                key_values => [ { name => 'ruckusSystemStatsNumSta' } ],
                output_template => 'Users count: %s',
                perfdatas => [
                    { label => 'users_count', template => '%s', unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-traffic-in', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalRxBytes', per_second => 1 } ],
                output_template => 'Total Traffic In: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'total_traffic_in', template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'total-traffic-out', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalTxBytes', per_second => 1 } ],
                output_template => 'Total Traffic Out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'total_traffic_out', template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'total-packets-in', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalRxPkts', per_second => 1 } ],
                output_template => 'Total Packets In: %s packets/s',
                perfdatas => [
                    { label => 'total_packets_in', template => '%s', min => 0, unit => 'packets/s' },
                ],
            }
        },
        { label => 'total-mcast-packets-in', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalRxMulticast', per_second => 1 } ],
                output_template => 'Total Multicast Packets In: %s packets/s',
                perfdatas => [
                    { label => 'total_mcast_packets_in', template => '%s', min => 0, unit => 'packets/s' },
                ],
            }
        },
        { label => 'total-packets-out', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalTxPkts', per_second => 1 } ],
                output_template => 'Total Packets Out: %s packets/s',
                perfdatas => [
                    { label => 'total_packets_out', template => '%s', min => 0, unit => 'packets/s' },
                ],
            }
        },
        { label => 'total-mcast-packets-out', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalTxMulticast', per_second => 1 } ],
                output_template => 'Total Multicast Packets Out: %s packets/s',
                perfdatas => [
                    { label => 'total_mcast_packets_out', template => '%s', min => 0, unit => 'packets/s' },
                ],
            }
        },
        { label => 'total-fail-packets-out', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalTxFail', per_second => 1 } ],
                output_template => 'Total Fail Packets Out: %s packets/s',
                perfdatas => [
                    { label => 'total_fail_packets_out', template => '%s', min => 0, unit => 'packets/s' },
                ],
            }
        },
        { label => 'total-retry-packets-out', set => {
                key_values => [ { name => 'ruckusSystemStatsWLANTotalTxRetry', per_second => 1 } ],
                output_template => 'Total Retry Packets Out: %s packets/s',
                perfdatas => [
                    { label => 'total_retry_packets_out', template => '%s', min => 0, unit => 'packets/s' },
                ],
            }
        },
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_ruckusSystemStatsNumAP = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.1.0';
my $oid_ruckusSystemStatsNumSta = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.2.0';
my $oid_ruckusSystemStatsWLANTotalRxPkts = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.5.0';
my $oid_ruckusSystemStatsWLANTotalRxBytes = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.6.0';
my $oid_ruckusSystemStatsWLANTotalRxMulticast = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.7.0';
my $oid_ruckusSystemStatsWLANTotalTxPkts = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.8.0';
my $oid_ruckusSystemStatsWLANTotalTxBytes = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.9.0';
my $oid_ruckusSystemStatsWLANTotalTxMulticast = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.10.0';
my $oid_ruckusSystemStatsWLANTotalTxFail = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.11.0';
my $oid_ruckusSystemStatsWLANTotalTxRetry = '.1.3.6.1.4.1.25053.1.3.1.1.1.15.12.0';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $result = $options{snmp}->get_leef(oids => [ $oid_ruckusSystemStatsNumAP, $oid_ruckusSystemStatsNumSta,
                                                    $oid_ruckusSystemStatsWLANTotalRxPkts, $oid_ruckusSystemStatsWLANTotalRxBytes,
                                                    $oid_ruckusSystemStatsWLANTotalRxMulticast, $oid_ruckusSystemStatsWLANTotalTxPkts,
                                                    $oid_ruckusSystemStatsWLANTotalTxBytes, $oid_ruckusSystemStatsWLANTotalTxMulticast,
                                                    $oid_ruckusSystemStatsWLANTotalTxFail, $oid_ruckusSystemStatsWLANTotalTxRetry ], 
                                          nothing_quit => 1);

    $self->{global} = {
        ruckusSystemStatsNumAP => $result->{$oid_ruckusSystemStatsNumAP},
        ruckusSystemStatsNumSta => $result->{$oid_ruckusSystemStatsNumSta},
        ruckusSystemStatsWLANTotalRxPkts => $result->{$oid_ruckusSystemStatsWLANTotalRxPkts},
        ruckusSystemStatsWLANTotalRxBytes => $result->{$oid_ruckusSystemStatsWLANTotalRxBytes},
        ruckusSystemStatsWLANTotalRxMulticast => $result->{$oid_ruckusSystemStatsWLANTotalRxMulticast},
        ruckusSystemStatsWLANTotalTxPkts => $result->{$oid_ruckusSystemStatsWLANTotalTxPkts},
        ruckusSystemStatsWLANTotalTxBytes => $result->{$oid_ruckusSystemStatsWLANTotalTxBytes},
        ruckusSystemStatsWLANTotalTxMulticast => $result->{$oid_ruckusSystemStatsWLANTotalTxMulticast},
        ruckusSystemStatsWLANTotalTxFail => $result->{$oid_ruckusSystemStatsWLANTotalTxFail},
        ruckusSystemStatsWLANTotalTxRetry => $result->{$oid_ruckusSystemStatsWLANTotalTxRetry},
    };

    $self->{cache_name} = "ruckus_scg_" . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'aps-count', 'users-count', 'total-traffic-in', 'total-traffic-out', 'total-packets-in',
'total-mcast-packets-in', 'total-packets-out', 'total-mcast-packets-out', 'total-fail-packets-in',
'total-retry-packets-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'aps-count', 'users-count', 'total-traffic-in', 'total-traffic-out', 'total-packets-in',
'total-mcast-packets-in', 'total-packets-out', 'total-mcast-packets-out', 'total-fail-packets-in',
'total-retry-packets-out'.

=back

=cut
    
