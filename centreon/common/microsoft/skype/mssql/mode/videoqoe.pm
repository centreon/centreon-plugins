package centreon::common::microsoft::skype::mssql::mode::videoqoe;

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
        { label => 'packet-loss', set => {
                key_values => [ { name => 'VideoPacketLossRate' } ],
                output_template => 'Packet Loss Rate: %.2f%%',
                perfdatas => [
                    { label => 'video_pckt_loss_rate', value => 'VideoPacketLossRate',
                      template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'post-fecplr', set => {
                key_values => [ { name => 'VideoPostFECPLR' } ],
                output_template => 'Packet Loss Rate After Correction: %.2f%%',
                perfdatas => [
                    { label => 'video_post_fecplr', value => 'VideoPostFECPLR',
                      template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'local-frame-loss', set => {
                key_values => [ { name => 'VideoLocalFrameLossPercentageAvg' } ],
                output_template => 'Video Frame Loss: %.2f%%',
                perfdatas => [
                    { label => 'video_frame_loss_prct_avg', value => 'VideoLocalFrameLossPercentageAvg',
                      template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'recv-frame', set => {
                key_values => [ { name => 'RecvFrameRateAverage' } ],
                output_template => 'Receiver Frame Rate: %.2f/s',
                perfdatas => [
                    { label => 'rcv_frame_rate_avg', value => 'RecvFrameRateAverage',
                      template => '%.2f', unit => 'frames/s', min => 0 },
                ],
            }
        },
        { label => 'inbound-frame', set => {
                key_values => [ { name => 'InboundVideoFrameRateAvg' } ],
                output_template => 'Inbound Video Frame Rate: %.2f%%',
                perfdatas => [
                    { label => 'inbound_video_frame_rate_avg', value => 'InboundVideoFrameRateAvg',
                      template => '%.2f', unit => '%', min => 0, max => 100 },
                ],
            }
        },
        { label => 'outbound-frame', set => {
                key_values => [ { name => 'OutboundVideoFrameRateAvg' } ],
                output_template => 'Outbound Video Frame Rate: %.2f%%',
                perfdatas => [
                    { label => 'outbound_video_frame_rate_avg', value => 'OutboundVideoFrameRateAvg',
                      template => '%.2f', unit => '%', min => 0, max => 100 },
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    my $query = "SELECT AVG(VideoPostFECPLR) AS VideoPostFECPLR,
                    AVG(VideoLocalFrameLossPercentageAvg) AS VideoLocalFrameLossPercentageAvg,
                    AVG(RecvFrameRateAverage) AS RecvFrameRateAverage,
                    AVG(VideoPacketLossRate) AS VideoPacketLossRate,
                    AVG(InboundVideoFrameRateAvg) AS InboundVideoFrameRateAvg,
                    AVG(OutboundVideoFrameRateAvg) AS OutboundVideoFrameRateAvg,
                    COUNT(*) AS TotalStreams
                FROM [QoEMetrics].[dbo].VideoStream
                WHERE ConferenceDateTime > (DATEADD(SECOND,-" . $self->{option_results}->{timeframe} . ",SYSUTCDATETIME()))
                AND ConferenceDateTime < SYSUTCDATETIME()";
    
    $self->{sql}->query(query => $query);

    my $results = $self->{sql}->fetchrow_hashref;

    $self->{global} = { 
        VideoPostFECPLR => (defined($results->{VideoPostFECPLR})) ? $results->{VideoPostFECPLR} : 0,
        VideoLocalFrameLossPercentageAvg => (defined($results->{VideoLocalFrameLossPercentageAvg})) ? $results->{VideoLocalFrameLossPercentageAvg} : 0,
        RecvFrameRateAverage => (defined($results->{RecvFrameRateAverage})) ? $results->{RecvFrameRateAverage} : 0,
        VideoPacketLossRate => (defined($results->{VideoPacketLossRate})) ? $results->{VideoPacketLossRate} : 0,
        InboundVideoFrameRateAvg => (defined($results->{InboundVideoFrameRateAvg})) ? $results->{InboundVideoFrameRateAvg} : 0,
        OutboundVideoFrameRateAvg => (defined($results->{OutboundVideoFrameRateAvg})) ? $results->{OutboundVideoFrameRateAvg} : 0,
    };
    $self->{count}->{TotalStreams} = $results->{TotalStreams} / $self->{option_results}->{timeframe};
}

1;

__END__

=head1 MODE

Check video stream QoE from SQL Server (Lync 2013, Skype 2015).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--timeframe>

Set the timeframe to query in seconds (Default: 900)

=item B<--warning-*>

Set warning thresholds.
Can be : 'recv-frame', 'local-frame-loss', 'post-fecplr',
'packet-loss', 'inboud-frame', 'outbound-frame'

=item B<--critical-*>

Set critical thresholds.
Can be : 'recv-frame', 'local-frame-loss', 'post-fecplr',
packet-loss', 'inboud-frame', 'outbound-frame'

=back

=cut
