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

package apps::cisco::cms::restapi::mode::systemstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Call Bridge activation is '%s', cluster enabled is '%s'",
        $self->{result_values}->{activated}, $self->{result_values}->{cluster_enabled});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{activated} = $options{new_datas}->{$self->{instance} . '_activated'};
    $self->{result_values}->{cluster_enabled} = $options{new_datas}->{$self->{instance} . '_clusterEnabled'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'legs', type => 0, cb_prefix_output => 'prefix_leg_output', skipped_code => { -10 => 1 } },
        { name => 'rates', type => 0, cb_prefix_output => 'prefix_rate_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'activated' }, { name => 'clusterEnabled' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    $self->{maps_counters}->{legs} = [
        { label => 'active-legs', set => {
                key_values => [ { name => 'callLegsActive' } ],
                output_template => 'Active: %d',
                perfdatas => [
                    { label => 'active_legs', value => 'callLegsActive', template => '%d',
                      min => 0, unit => 'legs' },
                ],
            }
        },
        { label => 'completed-legs', set => {
                key_values => [ { name => 'callLegsCompleted' } ],
                output_template => 'Completed: %d',
                perfdatas => [
                    { label => 'completed_legs', value => 'callLegsCompleted', template => '%d',
                      min => 0, unit => 'legs' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{rates} = [
        { label => 'audio-outgoing-rate', set => {
                key_values => [ { name => 'audioBitRateOutgoing' } ],
                output_template => 'outgoing audio streams: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'audio_outgoing_rate', value => 'audioBitRateOutgoing', template => '%d',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'audio-incoming-rate', set => {
                key_values => [ { name => 'audioBitRateIncoming' } ],
                output_template => 'incoming audio streams: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'audio_incoming_rate', value => 'audioBitRateIncoming', template => '%d',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'video-outgoing-rate', set => {
                key_values => [ { name => 'videoBitRateOutgoing' } ],
                output_template => 'outgoing video streams: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'video_outgoing_rate', value => 'videoBitRateOutgoing', template => '%d',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'video-incoming-rate', set => {
                key_values => [ { name => 'videoBitRateIncoming' } ],
                output_template => 'incoming video streams: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'video_incoming_rate', value => 'videoBitRateIncoming', template => '%d',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
    ];
}

sub prefix_leg_output {
    my ($self, %options) = @_;

    return "Legs ";
}

sub prefix_rate_output {
    my ($self, %options) = @_;

    return "Rates ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "filter-counters:s"     => { name => 'filter_counters' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{activated} !~ /true/i' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(method => '/system/status');

    $self->{global} = '';
    $self->{legs} = '';
    $self->{rates} = '';

    $self->{global} = {
        activated => $results->{activated},
        clusterEnabled => $results->{clusterEnabled},
    };
    $self->{legs} = {
        callLegsActive => $results->{callLegsActive},
        callLegsCompleted => $results->{callLegsCompleted},
    };
    $self->{rates} = {
        audioBitRateOutgoing => $results->{audioBitRateOutgoing},
        audioBitRateIncoming => $results->{audioBitRateIncoming},
        videoBitRateOutgoing => $results->{videoBitRateOutgoing},
        videoBitRateIncoming => $results->{videoBitRateIncoming},
    };
}

1;

__END__

=head1 MODE

Check system status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='rate')

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{activated}, %{cluster_enabled}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{activated} !~ /true/i').
Can use special variables like: %{activated}, %{cluster_enabled}

=item B<--warning-*>

Threshold warning.
Can be: 'active-legs', 'completed-legs', 'audio-outgoing-rate',
'audio-incoming-rate', 'video-outgoing-rate', 'video-incoming-rate'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-legs', 'completed-legs', 'audio-outgoing-rate',
'audio-incoming-rate', 'video-outgoing-rate', 'video-incoming-rate'.

=back

=cut
