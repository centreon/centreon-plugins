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

package network::polycom::rmx::snmp::mode::videoconferencingusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'calls-new', set => {
                key_values => [ { name => 'NewCallsLastMinTotal' } ],
                output_template => 'New Calls : %s (last min)',
                perfdatas => [
                    { label => 'calls_new', value => 'NewCallsLastMinTotal', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'calls-voice-active', set => {
                key_values => [ { name => 'ActiveCallsSummaryVoiceTotalCalls' } ],
                output_template => 'Current Voice Calls : %s',
                perfdatas => [
                    { label => 'calls_voice_active', value => 'ActiveCallsSummaryVoiceTotalCalls', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'calls-video-active', set => {
                key_values => [ { name => 'ActiveCallsSummaryVideoTotalCalls' } ],
                output_template => 'Current Video Calls : %s',
                perfdatas => [
                    { label => 'calls_video_active', value => 'ActiveCallsSummaryVideoTotalCalls', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'conferences-active', set => {
                key_values => [ { name => 'NumberActiveConferences' } ],
                output_template => 'Current Conferences : %s',
                perfdatas => [
                    { label => 'conferences_active', value => 'NumberActiveConferences', template => '%d', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_callNewCallsLastMinTotal = '.1.3.6.1.4.1.13885.110.1.4.2.1.0';
    my $oid_callActiveCallsSummaryVoiceTotalCalls = '.1.3.6.1.4.1.13885.110.1.4.4.1.1.0';
    my $oid_callActiveCallsSummaryVideoTotalCalls = '.1.3.6.1.4.1.13885.110.1.4.4.2.1.0';
    my $oid_conferenceNumberActiveConferences = '.1.3.6.1.4.1.13885.110.1.5.1.0';
    my $results = $options{snmp}->get_leef(oids => [$oid_callNewCallsLastMinTotal, $oid_callActiveCallsSummaryVoiceTotalCalls,
                                                    $oid_callActiveCallsSummaryVideoTotalCalls, $oid_conferenceNumberActiveConferences
                                                    ], nothing_quit => 1);

    $self->{global} = { NewCallsLastMinTotal => $results->{$oid_callNewCallsLastMinTotal},
                        ActiveCallsSummaryVoiceTotalCalls => $results->{$oid_callActiveCallsSummaryVoiceTotalCalls},
                        ActiveCallsSummaryVideoTotalCalls => $results->{$oid_callActiveCallsSummaryVideoTotalCalls},
                        NumberActiveConferences => $results->{$oid_conferenceNumberActiveConferences} };
}

1;

__END__

=head1 MODE

Check video conferencing usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='conferences-active'

=item B<--warning-*>

Threshold warning.
Can be: 'calls-new', 'calls-voice-active', 'calls-video-active', 'conferences-active'.

=item B<--critical-*>

Threshold critical.
Can be: 'calls-new', 'calls-voice-active', 'calls-video-active', 'conferences-active'.

=back

=cut
