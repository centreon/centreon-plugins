package apps::lync::2013::mssql::mode::videoqoe;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'video_post_fecplr', type => 0 },
        { name => 'video_local_frame_loss_prct_avg', type => 0 },
        { name => 'recv_frame_rate_avg', type => 0 },
        { name => 'video_packet_loss_rate', type => 0 },
        { name => 'inbound_video_frame_rate_avg', type => 0 },
        { name => 'outbound_video_frame_rate_avg', type => 0 },
    ];

    $self->{maps_counters}->{video_post_fecplr} = [
        { label => 'post-fecplr', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'VideoPostFECPLR : %d',
                perfdatas => [
                    { label => 'video_post_fecplr', value => 'value_absolute', template => '%d',
                      unit => '', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{video_local_frame_loss_prct_avg} = [
        { label => 'local-frame-loss', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'VideoLocalFrameLossPercentageAvg : %d',
                perfdatas => [
                    { label => 'video_frame_loss_prct_avg', value => 'value_absolute', template => '%d',
		       unit => '', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{recv_frame_rate_avg} = [
        { label => 'recv-frame', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'RecvFrameRateAverage : %d',
                perfdatas => [
                    { label => 'rcv_frame_rate_avg', value => 'value_absolute', template => '%d', 
                      unit => '', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{video_packet_loss_rate} = [
        { label => 'packet-loss', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'video_packet_loss_rate : %.2f%%',
                perfdatas => [
                    { label => 'video_pckt_loss_rate', value => 'value_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{inbound_video_frame_rate_avg} = [
        { label => 'inbound-frame', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'inbound_video_frame_rate_avg : %.2f%%',
                perfdatas => [
                    { label => 'inbound_video_frame_rate_avg', value => 'value_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{outbound_video_frame_rate_avg} = [
        { label => 'outbound-frame', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'outbound_video_frame_rate_avg : %.2f%%',
                perfdatas => [
                    { label => 'outbound_video_frame_rate_avg', value => 'value_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 0 },
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

    $self->{sql}->query(query => q{select avg(VideoPostFECPLR)
					,avg(VideoLocalFrameLossPercentageAvg)
					,avg(RecvFrameRateAverage)
					,avg(VideoPacketLossRate)
					,avg(InboundVideoFrameRateAvg)
					,avg(OutboundVideoFrameRateAvg)
				   from [QoEMetrics].[dbo].VideoStream
				}
			);

    my ($video_post_fecplr, $video_local_frame_loss_prct_avg, $recv_frame_rate_avg,
	    $video_packet_loss_rate, $inbound_video_frame_rate_avg, $outbound_video_frame_rate_avg) = $self->{sql}->fetchrow_array();

    $self->{video_post_fecplr} = { value => $video_post_fecplr };
    $self->{video_local_frame_loss_prct_avg} = { value => $video_local_frame_loss_prct_avg };
    $self->{recv_frame_rate_avg} = { value => $recv_frame_rate_avg };
    $self->{video_packet_loss_rate} = { value => $video_packet_loss_rate };
    $self->{inbound_video_frame_rate_avg} = { value => $inbound_video_frame_rate_avg };
    $self->{outbound_video_frame_rate_avg} = { value => $outbound_video_frame_rate_avg }; 

}

1;

__END__

=head1 MODE

Check video metrics QoE from SQL Server Lync Database [QoEMetrics].[dbo].VideoStream

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--warning-*>

Set warning threshold for QoE metrics. Can be : 'recv-frame', 'local-frame-loss', 'post-fecplr', ''packet-loss', 'inboud-frame', 'outbound-frame'

=item B<--critical-*>

Set critical threshold for QoE. Can be : 'recv-frame', 'local-frame-loss', 'post-fecplr', ''packet-loss', 'inboud-frame', 'outbound-frame'

=back

=cut
