#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::monitoring::iplabel::ekara::restapi::mode::scenarios;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use Date::Parse;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status: %s (%s)', $self->{result_values}->{status}, $self->{result_values}->{num_status});
}

sub prefix_scenario_output {
    my ($self, %options) = @_;

    return sprintf("Scenario '%s': ", $options{instance_value}->{display});
}

sub prefix_steps_output {
    my ($self, %options) = @_;

    return sprintf("  Step: %s, last exec: %s, ", $options{instance_value}->{display}, $options{instance_value}->{last_exec});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'scenarios', type => 3, cb_prefix_output => 'prefix_scenario_output', cb_long_output => 'prefix_scenario_output', indent_long_output => '    ', message_multiple => 'All scenarios are ok',
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'steps', display_long => 1, cb_prefix_output => 'prefix_steps_output',  message_multiple => 'All steps are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'scenario-status',
            type => 2,
            warning_default => '%{status} =~ /(Aborted|Stopped|Excluded|Degraded)/',
            critical_default => '%{status} =~ "Failure"',
            unknown_default => '%{status} =~ /(Unknown|No execution)/',
            set => {
                key_values => [ { name => 'status' }, { name => 'num_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'availability', nlabel => 'scenario.availability.percentage', set => {
                key_values => [ { name => 'availability' }, { name => 'display' } ],
                output_template => 'availability: %s%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'time-total-allsteps', nlabel => 'scenario.time.allsteps.total.milliseconds', set => {
                key_values => [ { name => 'time_total_allsteps' }, { name => 'display' } ],
                output_template => 'time total all steps: %sms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'time-interaction', nlabel => 'scenario.time.interaction.milliseconds', set => {
                key_values => [ { name => 'time_interaction' }, { name => 'display' } ],
                output_template => 'time interaction: %sms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        }
    ];
    $self->{maps_counters}->{steps} = [
        { label => 'time-step',  nlabel => 'scenario.step.time.milliseconds', set => {
                key_values => [ { name => 'time_step' }, { name => 'display' }, { name => 'last_exec' } ],
                output_template => 'time step: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
         { label => 'time-total',  nlabel => 'scenario.steps.time.total.milliseconds', set => {
                key_values => [ { name => 'time_total' }, { name => 'display' }, { name => 'last_exec' } ],
                output_template => 'time total: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {

        'filter-type:s'    => { name => 'filter_type' },
        'timeframe:s'      => { name => 'timeframe'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{timeframe} = defined($self->{option_results}->{timeframe})  && $self->{option_results}->{timeframe} ne '' ? $self->{option_results}->{timeframe} : '7500';
}

my $status_mapping = {
    0 => 'Unknown',
    1 => 'Success',
    2 => 'Failure',
    3 => 'Aborted',
    4 => 'No execution',
    5 => 'No execution',
    6 => 'Stopped',
    7 => 'Excluded',
    8 => 'Degraded'
};

sub manage_selection {
    my ($self, %options) = @_;
    my $results = $options{custom}->request_scenarios_status();

    my $time = time();
    my $start_date = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($time - $self->{timeframe}));
    my $end_date = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($time));
    foreach my $scenario (@$results) {
        my $scenario_detail = $options{custom}->request_api(
            endpoint => '/results-api/results/' . $scenario->{scenarioId},
            method => 'POST',
            get_param => [
                'from=' . $start_date,
                'to=' . $end_date
            ]
        );

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $scenario_detail->{infos}->{plugin_id} !~ /$self->{option_results}->{filter_type}/i) {
            $self->{output}->output_add(long_msg => "skipping scenario '" . $scenario->{scenarioName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{scenarios}->{ $scenario->{scenarioName} } = {
            display => $scenario->{scenarioName},
            global => {
                display => $scenario->{scenarioName},
                id => $scenario->{scenarioId},
                num_status => $scenario->{currentStatus},
                status => $status_mapping->{$scenario->{currentStatus}} // 'Unknown',
            }
        };
        if (!defined $scenario_detail->{results} or scalar(@{$scenario_detail->{results}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => "Scenario '" . $scenario->{scenarioName} . "' Don't have any performance data, please try to add a bigger timeframe");
            next;
        }
        foreach my $kpi (@{$scenario_detail->{kpis}}) {
            $self->{scenarios}->{ $scenario->{scenarioName} }->{global}->{$kpi->{label}} = $kpi->{value};
        }
        $self->{scenarios}->{ $scenario->{scenarioName} }->{steps_index}->{0} = 'Default';
        if ($scenario_detail->{infos}->{info}->{hasStep}) {
            foreach my $steps (@{$scenario_detail->{steps}}) {
                $self->{scenarios}->{ $scenario->{scenarioName} }->{steps_index}->{$steps->{index} - 1} = $steps->{name};
            }
        }

        foreach my $step_metrics (@{$scenario_detail->{results}}) {
            my $exec_time = str2time($step_metrics->{planningTime}, 'GMT');
            $self->{scenarios}->{ $scenario->{scenarioName} }->{steps}->{ $self->{scenarios}->{ $scenario->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} } }->{ $step_metrics->{metric} } = $step_metrics->{value};
            $self->{scenarios}->{ $scenario->{scenarioName} }->{steps}->{ $self->{scenarios}->{ $scenario->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} } }->{last_exec} = POSIX::strftime('%d-%m-%Y %H:%M:%S %Z', localtime($exec_time));
            $self->{scenarios}->{ $scenario->{scenarioName} }->{steps}->{ $self->{scenarios}->{ $scenario->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} } }->{display} = $self->{scenarios}->{ $scenario->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} };
        }
    }

    if (scalar(keys %{$self->{scenarios}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No scenario found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check ip-label Ekara scenarios.

=over 8

=item B<--timeframe>

Set timeframe period in seconds. (default: 7500)
Example: --timeframe='3600' will check the last hour
Note: If the API/Poller is overloaded, it is preferable to refine
this value according to the highest check frequency in the scenario.

=item B<--filter-type>

Filter by scenario type.
Can be: 'WEB', 'HTTPR', 'BROWSER PAGE LOAD'

=item B<--warning-scenario-status>

Warning threshold for scenario status (default: '%{status} !~ "Success"').
Syntax: --warning-scenario-status='%{status} =~ "xxx"'

=item B<--critical-scenario-status>

Critical threshold for scenario status (default: '%{status} =~ "Failure"').
Syntax: --critical-scenario-status='%{status} =~ "xxx"'

=item B<--warning-*> B<--critical-*>

Thresholds.
Common: 'availability' (%),
For WEB scenarios: 'time-total-allsteps' (ms), 'time-step' (ms),
For HTTPR scenarios: 'time-total' (ms),
FOR BPL scenarios: 'time-interaction' (ms), 'time-total' (ms).


=back

=cut
