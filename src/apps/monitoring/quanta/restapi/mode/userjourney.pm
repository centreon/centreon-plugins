#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::quanta::restapi::mode::userjourney;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 1, message_multiple => 'User journey is OK', cb_prefix_output => 'prefix_output', skipped_code => { -10 => 1 } }
    ];


    $self->{maps_counters}->{metrics} = [
        { label => 'journey-performance-score', nlabel => 'journey.performance.score', set => {
                key_values => [ { name => 'avg_lh_performance_score' }, { name => 'display' } ],
                output_template => 'journey performance score: %d',
                perfdatas => [
                    { value => 'avg_lh_performance_score', template => '%d',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'journey-hero-time', nlabel => 'journey.herotime.milliseconds', set => {
                key_values => [ { name => 'total_hero_time' }, { name => 'display' } ],
                output_template => 'journey hero time: %.2fms',
                perfdatas => [
                    { value => 'total_hero_time', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'journey-speed-index', nlabel => 'journey.speedindex.time.milliseconds', set => {
                key_values => [ { name => 'total_speed_index' }, { name => 'display' } ],
                output_template => 'journey speed index: %.2fms',
                perfdatas => [
                    { value => 'total_speed_index', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'journey-ttfb', nlabel => 'journey.ttfb.milliseconds', set => {
                key_values => [ { name => 'total_net_request_ttfb' }, { name => 'display' } ],
                output_template => 'journey ttfb: %.2fms',
                perfdatas => [
                    { value => 'total_net_request_ttfb', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'interaction-performance-score', nlabel => 'interaction.performance.score', set => {
                key_values => [ { name => 'lh_performance_score' }, { name => 'display' } ],
                output_template => 'performance score: %d',
                perfdatas => [
                    { value => 'lh_performance_score', template => '%d',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
         { label => 'hero-time', nlabel => 'herotime.milliseconds', set => {
                key_values => [ { name => 'hero_time' }, { name => 'display' } ],
                output_template => 'hero time: %.2fms',
                perfdatas => [
                    { value => 'hero_time', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'speed-index', nlabel => 'speedindex.time.milliseconds', set => {
                key_values => [ { name => 'speed_index' }, { name => 'display' } ],
                output_template => 'speed index: %.2fms',
                perfdatas => [
                    { value => 'speed_index', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'ttfb', nlabel => 'ttfb.milliseconds', set => {
                key_values => [ { name => 'net_request_ttfb' }, { name => 'display' } ],
                output_template => 'ttfb: %.2fms',
                perfdatas => [
                    { value => 'net_request_ttfb', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return $options{instance_value}->{type} . ' "' . $options{instance_value}->{name} . '" ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "journey-id:s"      => { name => 'journey_id' },
        "show-interactions" => { name => 'add_interactions' },
        "site-id:s"         => { name => 'site_id' },
        "timeframe:s"       => { name => 'timeframe', default => 300 }
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{journey_id} = (defined($self->{option_results}->{journey_id})) ? $self->{option_results}->{journey_id} : '';
    $self->{site_id} = (defined($self->{option_results}->{site_id})) ? $self->{option_results}->{site_id} : '';
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : '';

    if (!defined($self->{journey_id}) || $self->{journey_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --journey-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{site_id}) || $self->{site_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --site-id option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my $journey_metrics = [
        'avg_lh_performance_score',
        'total_hero_time',
        'total_net_request_ttfb',
        'total_speed_index'
    ];

    if (defined($self->{option_results}->{add_interactions})) {
        my $interaction_metrics = [
            'lh_performance_score',
            'speed_index',
            'hero_time',
            'net_request_ttfb'
        ];
        my $interactions_list = $options{custom}->list_objects(type => 'interactions', site_id => $self->{site_id}, journey_id => $self->{journey_id});
        foreach my $interaction (@{$interactions_list->{interactions}}) {
            my $interaction_payload;
            $interaction_payload->{type} = 'interaction';
            $interaction_payload->{id} = $interaction->{id};
            foreach (@$interaction_metrics) {
                push @{$interaction_payload->{metrics}}, { name => $_};
            }
            push @{$self->{resources_payload}->{resources}}, $interaction_payload;
        };
    }

    my $journey_payload;
    $journey_payload->{type} = 'journey';
    $journey_payload->{id} = $self->{journey_id};
    foreach (@$journey_metrics) {
        push @{$journey_payload->{metrics}}, { name => $_ };
    }
    push @{$self->{resources_payload}->{resources}}, $journey_payload;
    $self->{resources_payload}->{range} = $self->{timeframe};

    my $results = $options{custom}->get_data_export_api(data => $self->{resources_payload});

    foreach my $result (@{$results->{resources}}) {
        $self->{metrics}->{$result->{id}}->{display} = $result->{type} . "_" . $result->{name};
        $self->{metrics}->{$result->{id}}->{name} = $result->{name};
        $self->{metrics}->{$result->{id}}->{type} = $result->{type};
        foreach my $metric (@{$result->{metrics}}) {
            my $timestamp = 0;
            foreach my $timeserie (@{$metric->{values}}) {
                if ($timeserie->{timestamp} > $timestamp) {
                    $self->{metrics}->{$result->{id}}->{$metric->{name}} = $timeserie->{average};
                    $timestamp = $timeserie->{timestamp};
                }
            }
        }
    }
}

1;

__END__

=head1 MODE

Check Quanta by Centreon overview performance metrics.

=over 8

=item B<--site-id>

Set ID of the site (mandatory option).

=item B<--journey-id>

Set ID of the user journey (mandatory option).

=item B<--show-interactions>

Also monitor interactions (scenario's steps) of a user journey.

=item B<--timeframe>

Set timeframe in seconds (default: 86400).

=item B<--warning-*> B<--critical-*>

Thresholds.

=back

=cut
