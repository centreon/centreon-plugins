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

package hardware::devices::polycom::trio::restapi::mode::callsrt;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_loss_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $diff_pkts = ($options{new_datas}->{$self->{instance} . '_packets'} - $options{old_datas}->{$self->{instance} . '_packets'});
    my $diff_loss = ($options{new_datas}->{$self->{instance} . '_loss'} - $options{old_datas}->{$self->{instance} . '_loss'});

    $self->{result_values}->{packets_loss} = $diff_loss;
    $self->{result_values}->{packets_loss_prct} = 0;
    $self->{result_values}->{packets} = $diff_pkts;
    if ($diff_pkts > 0) {
        $self->{result_values}->{packets_loss_prct} = ($diff_loss * 100) / $diff_pkts;
    }

    return 0;
}

sub custom_loss_output {
    my ($self, %options) = @_;

    return sprintf(
        "packets loss: %.2f%% (%s on %s)",
        $self->{result_values}->{packets_loss_prct},
        $self->{result_values}->{packets_loss},
        $self->{result_values}->{packets}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'channels', type => 1, cb_prefix_output => 'prefix_channels_output', message_multiple => 'All call channels are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{channels} = [
        { label => 'channel-traffic-in', nlabel => 'call.channel.traffic.in.bytes', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'traffic in: %s %s/s',
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1  },
                ],
            }
        },
        { label => 'channel-traffic-out', nlabel => 'call.channel.traffic.out.bytes', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'traffic out: %s %s/s',
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1  },
                ],
            }
        },
        { label => 'channel-maxjitter', nlabel => 'call.channel.maxjitter.milliseconds', set => {
                key_values => [ { name => 'max_jitter' }, { name => 'display' } ],
                output_template => 'max jitter: %s ms',
                perfdatas => [
                    { template => '%d', unit => 'ms', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'channel-packetloss', nlabel => 'call.channel.packetloss.count', set => {
                key_values => [ { name => 'loss', diff => 1 }, { name => 'packets', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_loss_calc'),
                closure_custom_output => $self->can('custom_loss_output'),
                threshold_use => 'packets_loss',
                perfdatas => [
                    { value => 'packets_loss', template => '%d', min => 0, label_extra_instance => 1 }
                ],
            }
        },
        { label => 'channel-packetloss-prct', nlabel => 'call.channel.packetloss.percentage', display_ok => 0, set => {
                key_values => [ { name => 'loss', diff => 1 }, { name => 'packets', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_loss_calc'),
                closure_custom_output => $self->can('custom_loss_output'),
                threshold_use => 'packets_loss_prct',
                perfdatas => [
                    { value => 'packets_loss_prct', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_channels_output {
    my ($self, %options) = @_;

    return "Channel '" . $options{instance_value}->{display} ."' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'polycom_trio_' . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $result = $options{custom}->request_api(url_path => '/api/v1/mgmt/media/sessionStats');
    $self->{channels} = {};
    if (!defined($result->{data}) || ref($result->{data}) ne 'ARRAY') {
        $self->{output}->add_option_msg(short_msg => "cannot find session information.");
        $self->{output}->option_exit();
    }
    if (!defined($result->{data}->[0]->{Streams})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => ' no audio/video call running'
        );
        return ;
    }

    foreach (@{$result->{data}->[0]->{Streams}}) {
        $self->{channels}->{lc($_->{Category})} = {
            display => lc($_->{Category}),
            traffic_in => $_->{OctetsReceived},
            traffic_out => $_->{OctetsSent},
            max_jitter => $_->{MaxJitter},
            loss => $_->{PacketsLost},
            packets => $_->{PacketsReceived}
        };
    }
}

1;

__END__

=head1 MODE

Check call audio/video channels in real-time.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'channel-traffic-in', 'channel-traffic-out', 'channel-maxjitter'
'channel-packetloss', 'channel-packetloss-prct'.

=back

=cut
