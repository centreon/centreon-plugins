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

package hardware::devices::cisco::ces::restapi::mode::callsrt;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_traffic_calc {
    my ($self, %options) = @_;

    if (!defined($options{delta_time})) {
        $self->{error_msg} = 'Buffer creation';
        return -1;
    }

    my $total_bytes = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/\Q$self->{instance}\E_.*_bytes/) {
            my $new_bytes = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_bytes = $options{old_datas}->{$_};
            my $bytes = $new_bytes - $old_bytes;
            $bytes = $new_bytes if ($bytes < 0);

            $total_bytes += $bytes;
        }
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{traffic_per_seconds} = ($total_bytes * 8) / $options{delta_time};
    return 0;
}

sub custom_jitter_calc {
    my ($self, %options) = @_;

    my $max_jitter = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/\Q$self->{instance}\E_.*_maxjitter/) {
            $max_jitter = $options{new_datas}->{$_} if ($options{new_datas}->{$_} > $max_jitter);
        }
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{max_jitter} = $max_jitter;
    return 0;
}

sub custom_loss_calc {
    my ($self, %options) = @_;

    my ($total_loss, $total_pkts) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        if (/\Q$self->{instance}\E_.*_loss/) {
            my $new_loss = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_loss = $options{old_datas}->{$_};
            my $loss = $new_loss - $old_loss;
            $loss = $new_loss if ($loss < 0);

            $total_loss += $loss;
        } elsif (/\Q$self->{instance}\E_.*_packets/) {
            my $new_pkts = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_pkts = $options{old_datas}->{$_};
            my $pkts = $new_pkts - $old_pkts;
            $pkts = $new_pkts if ($pkts < 0);

            $total_pkts += $pkts;
        }
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{packets_loss} = $total_loss;
    $self->{result_values}->{packets_loss_prct} = 0;
    $self->{result_values}->{packets} = $total_pkts;
    if ($total_pkts > 0) {
        $self->{result_values}->{packets_loss_prct} = ($total_loss * 100) / $total_pkts;
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
        { label => 'channels-traffic', nlabel => 'call.channels.traffic.bytes', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'),
                output_template => 'traffic: %s %s/s',
                output_change_bytes => 1,
                output_use => 'traffic_per_seconds',  threshold_use => 'traffic_per_seconds',
                perfdatas => [
                    { value => 'traffic_per_seconds', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display'  }
                ]
            }
        },
        { label => 'channels-maxjitter', nlabel => 'call.channels.maxjitter.milliseconds', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_jitter_calc'),
                output_template => 'max jitter: %s ms',
                output_use => 'max_jitter',  threshold_use => 'max_jitter',
                perfdatas => [
                    { value => 'max_jitter', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display'  }
                ]
            }
        },
        { label => 'channels-packetloss', nlabel => 'call.channels.packetloss.count', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_loss_calc'),
                closure_custom_output => $self->can('custom_loss_output'),
                threshold_use => 'packets_loss',
                perfdatas => [
                    { value => 'packets_loss', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display'  }
                ]
            }
        },
        { label => 'channels-packetloss-prct', nlabel => 'call.channels.packetloss.percentage', display_ok => 0, set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_loss_calc'),
                closure_custom_output => $self->can('custom_loss_output'),
                threshold_use => 'packets_loss_prct',
                perfdatas => [
                    { value => 'packets_loss_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display'  }
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

    $self->{cache_name} = 'cces_' . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $result = $options{custom}->request_api(url_path => '/status.xml', ForceArray => ['Call']);
    foreach (('data~incoming', 'video~incoming~main', 'video~outgoing~main', 
        'video~outgoing~presentation', 'video~incoming~presentation',
        'audio~incoming~main', 'audio~outgoing~main')) {
        $self->{channels}->{$_} = { display => $_ };
    }

    if (!defined($result->{version}) || $result->{version} !~ /^(?:CE|TC)(\d+\.\d+)/i) {
        $self->{output}->add_option_msg(short_msg => 'cannot find firmware version');
        $self->{output}->option_exit();
    }
    my ($version_major, $version_minor) = split(/\./, $1);
    if (($version_major < 8) || ($version_major == 8 && $version_minor < 3)) {
        $self->{output}->add_option_msg(short_msg => 'firmware version is too old (' . $version_major . '.' . $version_minor . ')');
        $self->{output}->option_exit();
    }

    return if (!defined($result->{MediaChannels}->{Call}));

    foreach my $call (@{$result->{MediaChannels}->{Call}}) {
        foreach (@{$call->{Channel}}) {
            my $instance = lc($_->{Type}) . '~' . lc($_->{Direction});
            $instance .= '~' . lc($_->{Audio}->{ChannelRole}) if (defined($_->{Audio}));
            $instance .= '~' . lc($_->{Video}->{ChannelRole}) if (defined($_->{Video}));

            $self->{channels}->{$instance}->{$_->{item} . '_bytes'} = defined($_->{Netstat}->{Bytes}) ? $_->{Netstat}->{Bytes} : 0;
            $self->{channels}->{$instance}->{$_->{item} . '_maxjitter'} = $_->{Netstat}->{MaxJitter} if (defined($_->{Netstat}->{MaxJitter}));
            $self->{channels}->{$instance}->{$_->{item} . '_loss'} = defined($_->{Netstat}->{Loss}) ? $_->{Netstat}->{Loss} : 0;
            $self->{channels}->{$instance}->{$_->{item} . '_packets'} = defined($_->{Netstat}->{Packets}) ? $_->{Netstat}->{Packets} : 0;
        }
    }
}

1;

__END__

=head1 MODE

Check call channels in real-time (since CE 8.3)

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'channels-traffic', 'channels-maxjitter'
'channels-packetloss', 'channels-packetloss-prct'.

=back

=cut
