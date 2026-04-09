#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package cloud::cisco::webex::restapi::mode::workspacehealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'workspace',
            type             => 1,
            cb_prefix_output => 'prefix_output',
            skipped_code     => { -10 => 1 },
            message_multiple => 'All workspaces are ok'
        }
    ];

    $self->{maps_counters}->{workspace} = [
        {
            label            => 'status',
            type             => 2,
            unknown_default  => '',
            critical_default => '',
            warning_default  => '',
            set              =>
                {
                    key_values                     => [
                        { name => 'display_name' },
                        { name => 'type' },
                        { name => 'planned_maintenance' },
                        { name => 'health' }

                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'temperature', nlabel => 'temperature.celsius', set => {
            key_values      => [ { name => 'temperature' } ],
            output_template => 'Temperature: %d C',
            perfdatas       => [
                {
                    label    => 'temperature',
                    value    => 'temperature',
                    template => '%d',
                    unit     => 'C'
                }
            ],
        }
        },
        { label => 'humidity', nlabel => 'humidity.percentage', set => {
            key_values      => [ { name => 'humidity' } ],
            output_template => 'Humidity: %.2f%%',
            perfdatas       => [
                {
                    label    => 'humidity',
                    value    => 'humidity',
                    template => '%.2f',
                    min      => 0,
                    max      => 100,
                    unit     => '%'
                }
            ],
        }
        },
        { label => 'ambient-noise', nlabel => 'ambient.noise.dB', set => {
            key_values      => [ { name => 'ambient_noise' } ],
            output_template => 'Ambient noise: %.2f dB',
            perfdatas       => [
                {
                    template => '%.2f',
                    unit     => 'dB',
                    min      => 0
                },
            ],
        }
        },
        { label => 'tvoc', nlabel => 'tvoc', set => {
            key_values      => [ { name => 'tvoc' } ],
            output_template => 'TVOC: %.2f',
            perfdatas       => [
                {
                    template => '%.2f',
                    min      => 0
                },
            ],
        }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    my $pref = "workspace '" . $options{instance_value}->{display_name} . "'";

    if (defined($options{instance_value}->{type}) && $options{instance_value}->{type}) {
        $pref = $pref . " ($options{instance_value}->{type})";
    }

    $pref = $pref . " - " if defined($self->{option_results}->{add_metrics});
    return $pref;
}

sub custom_status_output {
    my ($self, %options) = @_;

    return "Workspace health: $self->{result_values}->{health} - Planed maintenance: $self->{result_values}->{planned_maintenance}";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'workspace-id:s' => { name => 'workspace_id' },
            'timeframe:s'    => { name => 'timeframe', default => 900 },
            'aggregation:s'  => { name => 'aggregation', default => 'none' },
            'zeroed'         => { name => 'zeroed' },
            'add-metrics'    => { name => 'add_metrics' },
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : undef;

    if ($self->{option_results}->{aggregation} !~ /^none|hourly|daily$/i) {
        $self->{output}->add_option_msg(short_msg => 'Unknown aggregation. Must be "none", "hourly" or "daily"');
        $self->{output}->option_exit();
    }
}

sub get_metric_value {
    my ($self, %options) = @_;

    my $start_time = DateTime->now->subtract(seconds => $self->{option_results}->{timeframe})->iso8601 . 'Z';
    my $end_time = DateTime->now->iso8601 . 'Z';

    my $params = {
        endpoint  =>
            "/v1/workspaceMetrics",
        get_param => [
            'metricName=' . $options{metric},
            'workspaceId=' . $self->{option_results}->{workspace_id},
            'aggregation=' . $self->{option_results}->{aggregation},
            'from=' . $start_time,
            'to=' . $end_time
        ]
    };

    my $response = $options{custom}->request_api(%$params);
    my $value_cnt = 0;
    my $value = 0;
    for my $item (@{$response->{items}}) {
        if (!defined($item->{value}) && !defined($item->{mean})) {
            next if (!defined($self->{option_results}->{zeroed}));
        }

        $value += $self->{option_results}->{aggregation} eq 'none' ?
            defined($item->{value}) ? $item->{value} : 0
            :
            defined($item->{mean}) ? $item->{mean} : 0;

        $value_cnt++;
    }

    if ($value_cnt > 0) {
        return $value / $value_cnt;
    }

    return undef;
}

sub manage_selection {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{workspace_id}) && $self->{option_results}->{workspace_id} ne '') {
        $self->{workspace} = $options{custom}->get_workspace();
    } else {
        my $workspaces = $options{custom}->get_workspaces();

        foreach my $workspace (@{$workspaces}) {
            $self->{workspace}->{$workspace->{id}} = $workspace;
        }
    }

    if (scalar(keys %{$self->{workspace}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No workspace found with this --workspace-id.");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{workspace_id}) && defined($self->{option_results}->{add_metrics})) {
        foreach my $id (keys %{$self->{workspace}}) {
            $self->{workspace}->{$id}->{temperature} = $self->get_metric_value(
                metric => 'temperature',
                custom => $options{custom}
            );

            $self->{workspace}->{$id}->{humidity} = $self->get_metric_value(
                metric => 'humidity',
                custom => $options{custom}
            );

            $self->{workspace}->{$id}->{ambient_noise} = $self->get_metric_value(
                metric => 'ambientNoise',
                custom => $options{custom}
            );

            $self->{workspace}->{$id}->{tvoc} = $self->get_metric_value(
                metric => 'tvoc',
                custom => $options{custom}
            );
        }
    }
}

1;

__END__

=head1 MODE

Check workspace status.

=over 8

=item B<--workspace-id>

Filter workspaces by workspace-id.

=item B<--add-metrics>

Requests the metric values from the API for the single workspace. Can be used only with --workspace-id.

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour, i.e 900 to check last 15 minutes). Default: 900.

=item B<--aggregation>

Define how the data must be aggregated. Available aggregations: C<none>, C<hourly>, C<daily>. Default: C<none>.

=item B<--zeroed>

Set metrics value to 0 if they are missing. Useful when some metrics are undefined.

=item B<--unknown-status>

Set unknown threshold for status. (Default: '')
You can use the following variables: C<%{planned_maintenance}>, C<%{health}>.
C<%(health)> can have one of these values: C<info>, C<ok>, C<warning>, C<error>

=item B<--warning--status>

Set warning threshold for status (Default: '')
You can use the following variables: C<%{planned_maintenance}>, C<%{health}>.
C<%(health)> can have one of these values: C<info>, C<ok>, C<warning>, C<error>

=item B<--critical-status>

Set critical threshold for status (Default: '').
You can use the following variables: C<%{planned_maintenance}>, C<%{health}>.
C<%(health)> can have one of these values: C<info>, C<ok>, C<warning>, C<error>

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: C<temperature> (C), C<humidity> (%), C<ambient_noise> (dB), C<tvoc>.

=item B<--cache-use>

Use the cache file instead of requesting the API (the cache file can be created with the cache mode).
The metrics are not get from the cache but always directly from the API.

=back

=cut