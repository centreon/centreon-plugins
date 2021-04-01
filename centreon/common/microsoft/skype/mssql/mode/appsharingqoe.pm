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

package centreon::common::microsoft::skype::mssql::mode::appsharingqoe;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'count', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'spoiled-tile-prct-total-avg', set => {
                key_values => [ { name => 'SpoiledTilePercentTotal' } ],
                output_template => 'Average Spoiled Tiles: %.2f%%',
                perfdatas => [
                    { label => 'spoiled_tile_prct_total_avg', value => 'SpoiledTilePercentTotal',
                      template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'rdp-tile-processing-latency-avg', set => {
                key_values => [ { name => 'RDPTileProcessingLatencyAverage' } ],
                output_template => 'Average RDP Tiles Processing Latency: %.2f ms',
                perfdatas => [
                    { label => 'rdp_tile_processing_latency_avg', value => 'RDPTileProcessingLatencyAverage',
                      template => '%.2f', unit => 'ms', min => 0 },
                ],
            }
        },
        { label => 'relative-one-way-average', set => {
                key_values => [ { name => 'RelativeOneWayAverage' } ],
                output_template => 'Average Amount of One-way Latency: %.2f ms',
                perfdatas => [
                    { label => 'relative_one_way_average', value => 'RelativeOneWayAverage',
                      template => '%.2f', unit => 'ms', min => 0 },
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

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query = "SELECT AVG(SpoiledTilePercentTotal) AS SpoiledTilePercentTotal,
                    AVG(RDPTileProcessingLatencyAverage) AS RDPTileProcessingLatencyAverage,
                    AVG(RelativeOneWayAverage) AS RelativeOneWayAverage,
                    COUNT(*) AS TotalStreams
                FROM [QoEMetrics].[dbo].AppSharingStream
                WHERE ConferenceDateTime > (DATEADD(SECOND,-" . $self->{option_results}->{timeframe} . ",SYSUTCDATETIME()))
                AND ConferenceDateTime < SYSUTCDATETIME()";

    $self->{sql}->query(query => $query);

    my $results = $self->{sql}->fetchrow_hashref;

    $self->{global} = { 
        SpoiledTilePercentTotal => (defined($results->{SpoiledTilePercentTotal})) ? $results->{SpoiledTilePercentTotal} : 0,
        RDPTileProcessingLatencyAverage => (defined($results->{RDPTileProcessingLatencyAverage})) ? $results->{RDPTileProcessingLatencyAverage} : 0,
        RelativeOneWayAverage => (defined($results->{RelativeOneWayAverage})) ? $results->{RelativeOneWayAverage} : 0,
    };
    $self->{count}->{TotalStreams} = $results->{TotalStreams} / $self->{option_results}->{timeframe};
}

1;

__END__

=head1 MODE

Check app sharing QoE metrics from SQL Server (Lync 2013, Skype 2015).

MS Recommandations :

SpoiledTilePercentTotal (Total percentage of the content that did not reach the viewer but was instead discarded and overwritten by fresh content)  > 36
RDPTileProcessingLatencyAverage (Average processing time for remote desktop protocol (RDP) tiles. A higher total equates to a longer delay in the viewing experience) > 400
RelativeOneWayAverage (Average amount of one-way latency. Relative one-way latency measures the delay between the client and the server) > 1.75

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--timeframe>

Set the timeframe to query in seconds (Default: 900)

=item B<--warning-*>

Set warning thresholds.
Can be : 'spoiled-tile-prct-total-avg', 'rdp-tile-processing-latency-avg',
'relative-one-way-average'

=item B<--critical-*>

Set critical thresholds.
Can be : 'spoiled-tile-prct-total-avg', 'rdp-tile-processing-latency-avg',
'relative-one-way-average'

=back

=cut
