#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::audiocodes::snmp::mode::sbccalls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5;

sub prefix_calls_output {
    my ($self, %options) = @_;

    return 'number of calls ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'call', type => 0, cb_prefix_output => 'prefix_calls_output', skipped_code => { -10 => 1 } },
        { name => 'session', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{call} = [
        { label => 'sbc-calls-duration-average', nlabel => 'sbc.calls.duration.average.seconds', set => {
                key_values => [ { name => 'callsAvgDuration' } ],
                output_template => 'average duration: %s s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'sbc-calls-active-inbound', nlabel => 'sbc.calls.active.inbound.count', set => {
                key_values => [ { name => 'callsInActive' } ],
                output_template => 'active inbound: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sbc-calls-active-outbound', nlabel => 'sbc.calls.active.outbound.count', set => {
                key_values => [ { name => 'callsOutActive' } ],
                output_template => 'active outbound: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sbc-calls-established-inbound', nlabel => 'sbc.calls.established.inbound.count', set => {
                key_values => [ { name => 'callsInTotalEst', diff => 1 } ],
                output_template => 'established inbound: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sbc-calls-established-outbound', nlabel => 'sbc.calls.established.outbound.count', set => {
                key_values => [ { name => 'callsOutTotalEst', diff => 1 } ],
                output_template => 'established outbound: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sbc-calls-notestablished-inbound-failed', nlabel => 'sbc.calls.notestablished.inbound.failed.count', set => {
                key_values => [ { name => 'callsInFailedNotEst', diff => 1 } ],
                output_template => 'not established inbound failed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sbc-calls-notestablished-outbound', nlabel => 'sbc.calls.notestablished.outbound.failed.count', set => {
                key_values => [ { name => 'callsOutFailedNotEst', diff => 1 } ],
                output_template => 'not established outbound failed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{session} = [
        { label => 'sbc-sessions-active', nlabel => 'sbc.sessions.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active sessions: %s',
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

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        callsAvgDuration     => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.1' }, # acKpiSbcCallStatsCurrentGlobalAverageCallDuration
        callsInActive        => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.2' }, # acKpiSbcCallStatsCurrentGlobalActiveCallsIn
        callsOutActive       => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.3' }, # acKpiSbcCallStatsCurrentGlobalActiveCallsOut
        callsInTotalEst      => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.8' }, # acKpiSbcCallStatsCurrentGlobalEstablishedCallsInTotal
        callsOutTotalEst     => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.9' }, # acKpiSbcCallStatsCurrentGlobalEstablishedCallsOutTotal
        callsInFailedNotEst  => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.19' }, # acKpiSbcCallStatsCurrentGlobalNotEstablishFailedCallsInTotal
        callsOutFailedNotEst => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.20' }, # acKpiSbcCallStatsCurrentGlobalNotEstablishFailedCallsOutTotal
        activeSessions       => { oid => '.1.3.6.1.4.1.5003.15.3.1.1.1.43' }  # acKpiSbcCallStatsCurrentGlobalActiveSessions
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    $self->{call} = $result;
    $self->{session} = { active => $result->{activeSessions} };

    $self->{cache_name} = 'audiocodes_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        Digest::MD5::md5_hex(
            defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : ''
        );
}

1;

__END__

=head1 MODE

Check SBC calls.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^calls'

=item B<--warning-*> B<--critical-*>

Threshold.
Can be: 'sbc-calls-duration-average', 'sbc-calls-active-inbound', 'sbc-calls-active-outbound',
'sbc-calls-established-inbound', 'sbc-calls-established-outbound',
'sbc-calls-notestablished-inbound-failed', 'sbc-calls-notestablished-outbound', 'sbc-sessions-active'.

=back

=cut
