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

package centreon::common::microsoft::skype::mssql::mode::audioqoe;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'jitter', type => 0, cb_prefix_output => 'prefix_jitter_output', skipped_code => { -10 => 1 } },
        { name => 'packet', type => 0, cb_prefix_output => 'prefix_packet_output', skipped_code => { -10 => 1 } },
        { name => 'count', type => 0 },
    ];

    $self->{maps_counters}->{jitter} = [
        { label => 'jitter-avg', set => {
                key_values => [ { name => 'JitterAvg' } ],
                output_template => 'Average: %d ms',
                perfdatas => [
                    { label => 'jitter_avg', value => 'JitterAvg', template => '%d', 
                      unit => 'ms', min => 0 },
                ],
            }
        },
        { label => 'jitter-min', set => {
                key_values => [ { name => 'JitterMin' } ],
                output_template => 'Min: %d ms',
                perfdatas => [
                    { label => 'jitter_min', value => 'JitterMin', template => '%d',
                      unit => 'ms', min => 0 },
                ],
            }
        },
        { label => 'jitter-max', set => {
                key_values => [ { name => 'JitterMax' } ],
                output_template => 'Max: %d ms',
                perfdatas => [
                    { label => 'jitter_max', value => 'JitterMax', template => '%d',
                      unit => 'ms', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{packet} = [
        { label => 'loss-avg', set => {
                key_values => [ { name => 'PacketLossAvg' } ],
                output_template => 'Average: %.2f%%',
                perfdatas => [
                    { label => 'pckt_loss_avg', value => 'PacketLossAvg', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'loss-min', set => {
                key_values => [ { name => 'PacketLossMin' } ],
                output_template => 'Min: %.2f%%',
                perfdatas => [
                    { label => 'pckt_loss_min', value => 'PacketLossMin', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'loss-max', set => {
                key_values => [ { name => 'PacketLossMax' } ],
                output_template => 'Max: %.2f%%',
                perfdatas => [
                    { label => 'pckt_loss_max', value => 'PacketLossMax', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{count} = [
        { label => 'stream-count', set => {
                key_values => [ { name => 'TotalStreams' } ],
                output_template => 'Streams Count: %.2f/s',
                perfdatas => [
                    { label => 'stream_count', value => 'TotalStreams', template => '%.2f',
                      unit => 'streams/s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_jitter_output {
    my ($self, %options) = @_;

    return "Jitter ";
}

sub prefix_packet_output {
    my ($self, %options) = @_;

    return "Packets Loss ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "timeframe:s"           => { name => 'timeframe', default => '900' },
                                    "filter-counters:s"     => { name => 'filter_counters', default => '' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query = "SELECT MIN(CAST(JitterInterArrival AS BIGINT)) AS JitterMin,
                    MAX(CAST(JitterInterArrival AS BIGINT)) AS JitterMax,
                    AVG(CAST(JitterInterArrival AS BIGINT)) AS JitterAvg,
                    MIN(PacketLossRate) AS PacketLossMin,
                    MAX(PacketLossRate) AS PacketLossMax,
                    AVG(PacketLossRate) AS PacketLossAvg,
                    COUNT(*) AS TotalStreams
                FROM [QoEMetrics].[dbo].AudioStream
                WHERE ConferenceDateTime > (DATEADD(SECOND,-" . $self->{option_results}->{timeframe} . ",SYSUTCDATETIME()))
                AND ConferenceDateTime < SYSUTCDATETIME()";

    $self->{sql}->query(query => $query);

    my $results = $self->{sql}->fetchrow_hashref;

    $self->{jitter} = { 
        JitterMin => (defined($results->{JitterMin})) ? $results->{JitterMin} : 0,
        JitterMax => (defined($results->{JitterMax})) ? $results->{JitterMax} : 0,
        JitterAvg => (defined($results->{JitterAvg})) ? $results->{JitterAvg} : 0,
    };
    $self->{packet} = { 
        PacketLossMin => (defined($results->{PacketLossMin})) ? $results->{PacketLossMin} : 0,
        PacketLossMax => (defined($results->{PacketLossMax})) ? $results->{PacketLossMax} : 0,
        PacketLossAvg => (defined($results->{PacketLossAvg})) ? $results->{PacketLossAvg} : 0,
    };
    $self->{count}->{TotalStreams} = $results->{TotalStreams} / $self->{option_results}->{timeframe};
}

1;

__END__

=head1 MODE

Check audio stream QoE metrics from SQL Server (Lync 2013, Skype 2015).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--timeframe>

Set the timeframe to query in seconds (Default: 900)

=item B<--warning-*>

Set warning thresholds.
Can be : 'jitter-min', 'jitter-max', 'jitter-avg',
'loss-min', 'loss-max', 'loss-avg'

=item B<--critical-*>

Set critical thresholds.
Can be : 'jitter-min', 'jitter-max', 'jitter-avg',
'loss-min', 'loss-max', 'loss-avg'

=back

=cut
