#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::cisco::wsa::snmp::mode::cache;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
            message_separator => ' - ',
            skipped_code => { -10 => 1 },
        },
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'cacheTotalHttpReqs',
            set => {
                key_values => [ { name => 'cacheTotalHttpReqs' } ],
                output_template => 'Total number of HTTP requests from clients is: %d',
                perfdatas => [
                    {
                        label => 'cacheTotalHttpReqs',
                        value => 'cacheTotalHttpReqs_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

        {
            label => 'cacheMeanRespTime',
            set => {
                key_values => [ { name => 'cacheMeanRespTime' } ],
                output_template => 'The HTTP mean response time is: %d',
                perfdatas => [
                    {
                        label => 'cacheMeanRespTime',
                        value => 'cacheMeanRespTime_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

        {
            label => 'cacheMeanMissRespTime',
            set => {
                key_values => [ { name => 'cacheMeanMissRespTime' } ],
                output_template => 'The HTTP mean response time of Misses is: %d',
                perfdatas => [
                    {
                        label => 'cacheMeanMissRespTime',
                        value => 'cacheMeanMissRespTime_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

        {
            label => 'cacheMeanHitRespTime',
            set => {
                key_values => [ { name => 'cacheMeanHitRespTime' } ],
                output_template => 'The HTTP mean response time of Hits is: %d',
                perfdatas => [
                    {
                        label => 'cacheMeanHitRespTime',
                        value => 'cacheMeanHitRespTime_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

        {
            label => 'cacheMeanHitRatio',
            set => {
                key_values => [ { name => 'cacheMeanHitRatio' } ],
                output_template => 'The HTTP hit ratio is: %d',
                perfdatas => [
                    {
                        label => 'cacheMeanHitRatio',
                        value => 'cacheMeanHitRatio_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

        {
            label => 'cacheMeanByteHitRatio',
            set => {
                key_values => [ { name => 'cacheMeanByteHitRatio' } ],
                output_template => 'The HTTP byte hit ratio is %d',
                perfdatas => [
                    {
                        label => 'cacheMeanByteHitRatio',
                        value => 'cacheMeanByteHitRatio_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

        {
            label => 'cacheTotalBandwidthSaving',
            set => {
                key_values => [ { name => 'cacheTotalBandwidthSaving' } ],
                output_template => 'The total bandwidth savings for HTTP is: %d Mbits/sec',
                perfdatas => [
                    {
                        label => 'cacheTotalBandwidthSaving',
                        value => 'cacheTotalBandwidthSaving_absolute',
                        template => '%d',
                        min => 0,
                        unit => 'Mbits/sec'
                    },
                ],
            }
        },

        {
            label => 'cacheDuration',
            set => {
                key_values => [ { name => 'cacheDuration' } ],
                output_template => 'The proxy up time is: %d',
                perfdatas => [
                    {
                        label => 'cacheDuration',
                        value => 'cacheDuration_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

        {
            label => 'cacheCltReplyErrPct',
            set => {
                key_values => [ { name => 'cacheCltReplyErrPct' } ],
                output_template => 'The percentage of errors in the HTTP replies to client is: %d',
                perfdatas => [
                    {
                        label => 'cacheCltReplyErrPct',
                        value => 'cacheCltReplyErrPct_absolute',
                        template => '%d',
                        min => 0,
                    },
                ],
            }
        },

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                       {
                                       });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %oids = (
        cacheTotalHttpReqs =>        '.1.3.6.1.4.1.15497.1.2.3.6.1',
        cacheMeanRespTime =>         '.1.3.6.1.4.1.15497.1.2.3.6.2',
        cacheMeanMissRespTime =>     '.1.3.6.1.4.1.15497.1.2.3.6.3',
        cacheMeanHitRespTime =>      '.1.3.6.1.4.1.15497.1.2.3.6.4',
        cacheMeanHitRatio =>         '.1.3.6.1.4.1.15497.1.2.3.6.5',
        cacheMeanByteHitRatio =>     '.1.3.6.1.4.1.15497.1.2.3.6.6',
        cacheTotalBandwidthSaving => '.1.3.6.1.4.1.15497.1.2.3.6.7',
        cacheDuration =>             '.1.3.6.1.4.1.15497.1.2.3.6.8',
        cacheCltReplyErrPct =>       '.1.3.6.1.4.1.15497.1.2.3.6.9',
    );
    my $result = $options{snmp}->get_leef(oids => [values %oids], nothing_quit => 1);
    $self->{global} = {};
    foreach (keys %oids) {
        $self->{global}->{$_} = $result->{$oids{$_}} if (defined($result->{$oids{$_}}));
    }
}

1;

__END__

=head1 MODE

Check 'TotalHttpReqs', 'MeanRespTime', 'MeanMissRespTime', 'MeanHitRespTime', 'MeanHitRatio', 'MeanByteHitRatio', 'TotalBandwidthSaving', 'Duration', 'CltReplyErrPct' through caching mechanism (ASYNCOSWEBSECURITYAPPLIANCE-MIB).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'cacheTotalHttpReqs', 'cacheMeanRespTime', 'cacheMeanMissRespTime', 'cacheMeanHitRespTime', 'cacheMeanHitRatio', 'cacheMeanByteHitRatio', 'cacheTotalBandwidthSaving', 'cacheDuration', 'cacheCltReplyErrPct'

=item B<--critical-*>

Threshold critical.
Can be: 'cacheTotalHttpReqs', 'cacheMeanRespTime', 'cacheMeanMissRespTime', 'cacheMeanHitRespTime', 'cacheMeanHitRatio', 'cacheMeanByteHitRatio', 'cacheTotalBandwidthSaving', 'cacheDuration', 'cacheCltReplyErrPct'

=back

=cut
