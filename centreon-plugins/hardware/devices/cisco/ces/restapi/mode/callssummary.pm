#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package hardware::devices::cisco::ces::restapi::mode::callssummary;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub custom_loss_output {
    my ($self, %options) = @_;

    return sprintf(
        "packets loss: %.2f%% (%s on %s)",
        $self->{result_values}->{loss_prct},
        $self->{result_values}->{loss},
        $self->{result_values}->{pkts}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return $options{instance_value}->{label} . ' ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'global_video_incoming', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 } },
        { name => 'global_video_outgoing', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 } },
        { name => 'global_audio_incoming', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 } },
        { name => 'global_audio_outgoing', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-finished', nlabel => 'calls.total.finished.count', set => {
                key_values => [ { name => 'new_calls' } ],
                output_template => 'total calls finished: %d',
                perfdatas => [
                    { value => 'new_calls', template => '%d', min => 0 },
                ],
            }
        }
    ];
    
    foreach my $type (('video', 'audio')) {
        foreach my $direction (('incoming', 'outgoing')) {
            $self->{maps_counters}->{'global_' . $type . '_' . $direction} = [
                { label => 'packetloss', nlabel => 'calls.' . $type . '.' . $direction . '.packetloss.count', set => {
                        key_values => [ { name => 'loss' }, { name => 'pkts' }, { name => 'loss_prct' } ],
                        closure_custom_output => $self->can('custom_loss_output'),
                        perfdatas => [
                            { value => 'loss', template => '%d', min => 0  },
                        ],
                    }
                },
                { label => 'packetloss-prct', nlabel => 'calls.' . $type . '.' . $direction . '.packetloss.percentage', display_ok => 0, set => {
                        key_values => [ { name => 'loss_prct' }, { name => 'loss' }, { name => 'pkts' } ],
                        closure_custom_output => $self->can('custom_loss_output'),
                        perfdatas => [
                            { value => 'loss_prct', template => '%d', unit => '%', min => 0, max => 100 },
                        ],
                    }
                },
                { label => 'maxjitter', nlabel => 'calls.' . $type . '.' . $direction . '.maxjitter.count', set => {
                        key_values => [ { name => 'maxjitter' } ],
                        output_template => 'max jitter: %s ms',
                        perfdatas => [
                            { value => 'maxjitter', template => '%d', unit => 'ms', min => 0  },
                        ],
                    }
                },
            ];
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{statefile_cache}->read(
        statefile => 'cces_' . $options{custom}->{hostname}  . '_' . $self->{mode} . '_' .
            (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'))
    );
    my $last_call_endtime = $self->{statefile_cache}->get(name => 'last_call_endtime');
    $last_call_endtime = 0 if (!defined($last_call_endtime));

    my $result = $options{custom}->request_api(
        method => 'POST',
        url_path => '/putxml',
        query_form_post => '<Command><CallHistory><Get><DetailLevel>Full</DetailLevel></Get></CallHistory></Command>',
        ForceArray => ['Entry']
    );

    $self->{global} = { new_calls => 0 };
    $self->{global_video_incoming} = { loss => 0, pkts => 0, loss_prct => 0, maxjitter => 0, label => 'video incoming' };
    $self->{global_video_outgoing} = { loss => 0, pkts => 0, loss_prct => 0, maxjitter => 0, label => 'video outgoing' };
    $self->{global_audio_incoming} = { loss => 0, pkts => 0, loss_prct => 0, maxjitter => 0, label => 'audio incoming' };
    $self->{global_audio_outgoing} = { loss => 0, pkts => 0, loss_prct => 0, maxjitter => 0, label => 'audio outgoing' };

    return if (!defined($result->{CallHistoryGetResult}->{Entry}));

    my $save_last_time = 0;
    foreach (@{$result->{CallHistoryGetResult}->{Entry}}) {
        my $end_time = Date::Parse::str2time($_->{EndTimeUTC});
        if (!defined($end_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "can't parse date '" . $_->{EndTimeUTC} . "'"
            );
            next;
        }
        $save_last_time = $end_time if ($save_last_time < $end_time);
        next if ($end_time <= $last_call_endtime);

        $self->{global}->{new_calls}++;
        foreach my $type (('Video', 'Audio')) {
            foreach my $direction (('Incoming', 'Outgoing')) {
                $self->{'global_' . lc($type) . '_' . lc($direction)}->{maxjitter}  = $_->{$type}->{$direction}->{MaxJitter}
                    if ($self->{'global_' . lc($type) . '_' . lc($direction)}->{maxjitter} < $_->{$type}->{$direction}->{MaxJitter});
                if ($_->{$type}->{$direction}->{PacketLoss} =~ /^(\d+)\/(\d+)/) {
                    $self->{'global_' . lc($type) . '_' . lc($direction)}->{loss} += $1;
                    $self->{'global_' . lc($type) . '_' . lc($direction)}->{pkts} += $2;
                }
            }
        }
    }

    foreach my $type (('video', 'audio')) {
        foreach my $direction (('incoming', 'outgoing')) {
            $self->{'global_' . $type . '_' . $direction}->{loss_prct} = $self->{'global_' . $type . '_' . $direction}->{loss} * 100 / $self->{'global_' . $type . '_' . $direction}->{pkts}
                if ($self->{'global_' . $type . '_' . $direction}->{pkts} > 0);
        }
    }

    $self->{statefile_cache}->write(data => { last_call_endtime => $save_last_time });
}

1;

__END__

=head1 MODE

Check call history.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-finished', 'packetloss'
'packetloss-prct', 'maxjitter'.

=back

=cut
