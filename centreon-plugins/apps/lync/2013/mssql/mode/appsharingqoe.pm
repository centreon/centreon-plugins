#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::lync::2013::mssql::mode::appsharingqoe;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'spoiled_tile_prct_total_avg', type => 0 },
        { name => 'rdp_tile_processing_latency_avg', type => 0 },
        { name => 'relative_one_way_average', type => 0 },
    ];

    $self->{maps_counters}->{spoiled_tile_prct_total_avg} = [
        { label => 'spoiled-tile-prct-total-avg', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'SpoiledTilePercentTotal(Avg) : %.2f ms',
                perfdatas => [
                    { label => 'spoiled_tile_prct_total_avg', value => 'value_absolute', template => '%.2f',
                      unit => 'ms', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{rdp_tile_processing_latency_avg} = [
        { label => 'rdp-tile-processing-latency-avg', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'RDPTileProcessingLatencyAverage : %.2f ms',
                perfdatas => [
                    { label => 'rdp_tile_processing_latency_avg', value => 'value_absolute', template => '%.2f',
		       unit => 'ms', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{relative_one_way_average} = [
        { label => 'relative-one-way-average', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'RelativeOneWayAverage : %.2f ms',
                perfdatas => [
                    { label => 'relative_one_way_average', value => 'value_absolute', template => '%.2f', 
                      unit => 'ms', min => 0, label_extra_instance => 0 },
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
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    $self->{sql}->query(query => q{SELECT avg(SpoiledTilePercentTotal) 
			           ,avg(RDPTileProcessingLatencyAverage)
				   ,avg(RelativeOneWayAverage)
				   FROM [QoEMetrics].[dbo].AppSharingStream});

    my ($spoiled_tile_prct_total_avg, $rdp_tile_processing_latency_avg, $relative_one_way_average) = $self->{sql}->fetchrow_array();
    
    $self->{spoiled_tile_prct_total_avg} = { value => $spoiled_tile_prct_total_avg };
    $self->{rdp_tile_processing_latency_avg} = { value => $rdp_tile_processing_latency_avg };
    $self->{relative_one_way_average} = { value => $relative_one_way_average };

}

1;

__END__

=head1 MODE

Check AppSharing Qoe metrics from SQL Server Lync 2013 Database ([QoEMetrics].[dbo].AppSharingStream)

MS Recommandations :

SpoiledTilePercentTotal (Total percentage of the content that did not reach the viewer but was instead discarded and overwritten by fresh content)  > 36
RDPTileProcessingLatencyAverage (Average processing time for remote desktop protocol (RDP) tiles. A higher total equates to a longer delay in the viewing experience) > 400
RelativeOneWayAverage (Average amount of one-way latency. Relative one-way latency measures the delay between the client and the server) > 1.75

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--warning-*>

Set warning threshold for number of user. Can be : 'spoiled-tile-prct-total-avg', 'rdp-tile-processing-latency-avg', 'relative-one-way-average'

=item B<--critical-*>

Set critical threshold for number of user. Can be : 'spoiled-tile-prct-total-avg', 'rdp-tile-processing-latency-avg', 'relative-one-way-average'

=back

=cut
