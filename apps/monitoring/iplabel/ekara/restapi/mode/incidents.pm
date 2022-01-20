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

package apps::monitoring::iplabel::ekara::restapi::mode::incidents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use Date::Parse;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status: %s', $self->{result_values}->{status});
}

sub custom_duration_output {
    my ($self, %options) = @_;
    if ($self->{result_values}->{status} =~ 'Ongoing') {
        return sprintf(
            'start time: %s, duration: %s',
            $self->{result_values}->{start_time},
            centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration})
        );
    } else {
        return sprintf(
            'start time: %s, end time: %s, duration: %s',
            $self->{result_values}->{start_time},
            $self->{result_values}->{end_time},
            centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration})
        );
    }
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Incidents ';
}

sub prefix_incidents_output {
    my ($self, %options) = @_;

    return "Scenario '" . $options{instance_value}->{display} . "': ";
}

sub prefix_steps_output {
    my ($self, %options) = @_;

    return sprintf("Step: %s, last exec: %s, ", $options{instance_value}->{display}, $options{instance_value}->{last_exec});
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'incidents', type => 3, cb_prefix_output => 'prefix_incidents_output', cb_long_output => 'prefix_incidents_output', indent_long_output => '    ', message_multiple => 'No current incidents',
            group => [
                { name => 'incident', type => 0, skipped_code => { -10 => 1 } },
                { name => 'triggers', display_long => 1, cb_prefix_output => 'prefix_triggers_output',  message_multiple => 'All steps are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'incidents-total', nlabel => 'ekara.incidents.current.total.count', set => {
                key_values      => [ { name => 'total' }  ],
                output_template => 'total current: %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{incident} = [
        { label => 'status',
            type => 2,
            warning_default => '',
            critical_default => '%{status} =~ "Ongoing"',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'severity',
            type => 2,
            warning_default => '',
            critical_default => '%{severity} =~ "Critical"',
            set => {
                key_values => [ { name => 'severity' }, { name => 'display' } ],
                output_template => 'severity: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'duration', nlabel => 'ekara.incident.duration.seconds', set => {
                key_values => [ { name => 'duration' }, { name => 'start_time' }, { name => 'end_time' }, { name => 'status'} ],
                closure_custom_output => $self->can('custom_duration_output'),
                perfdatas => [
                    { template => '%s', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{triggers} = [
        { label => 'time-step',  nlabel => 'transaction.duration.milliseconds', set => {
                key_values => [ { name => 'time_step' }, { name => 'display' }, { name => 'last_exec' } ],
                output_template => 'time step: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
         { label => 'time-total',  nlabel => 'transaction.duration.milliseconds', set => {
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
        'filter-id:s'      => { name => 'filter_id' },
        'filter-name:s'    => { name => 'filter_name' },
        'filter-status:s@' => { name => 'filter_status' },
        'filter-type:s'    => { name => 'filter_type' },
        'ignore-closed'    => { name => 'ignore_closed' },
        'interval:s'       => { name => 'interval'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : '900';
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

    my $status_filter = {};
    if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status}[0] ne '') {
        $status_filter->{statusFilter} = $self->{option_results}->{filter_status};
    }

    my $results = $options{custom}->request_api(
        endpoint => '/results-api/scenarios/status',
        method => 'POST',
        post_body => $status_filter
    );

    my $scenarios_list = {};
    foreach (@$results) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{scenarioName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping scenario '" . $_->{scenarioName} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $_->{scenarioId} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping scenario '" . $_->{scenarioName} . "': no matching filter.", debug => 1);
            next;
        }
        push @{$scenarios_list->{scenarioIds}}, $_->{scenarioId};
    }

    my $time = time();
    my $end_date = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($time));
    my $start_date = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($time - $self->{interval}));
    my $incidents = $options{custom}->request_api(
        endpoint => '/results-api/incidents',
        method => 'POST',
        get_param => [
            'from=' . $start_date,
            'to=' . $end_date
        ],
        post_body => $scenarios_list
    );

    $self->{global}->{total} = 0;
    foreach my $incident (@$incidents) {
        my $start_time = str2time($incident->{startTime}, 'GMT');
        my $end_time = defined($incident->{endTime}) ? str2time($incident->{endTime}, 'GMT') : time();
        next if (defined($self->{option_results}->{ignore_closed}) && defined($incident->{endTime}));


        $self->{incidents}->{$incident->{ssr_id}}->{display} = $incident->{scnName};
        $self->{incidents}->{$incident->{ssr_id}}->{incident} = {
            display => $incident->{scnName},
            scenario_id => $incident->{scn_id},
            status => defined($incident->{endTime}) ? 'Closed' : 'Ongoing',
            severity => $incident->{severity},
            start_time => POSIX::strftime('%d-%m-%Y %H:%M:%S', localtime($start_time)),
            end_time => POSIX::strftime('%d-%m-%Y %H:%M:%S', localtime($end_time)),
            duration => $end_time - $start_time
        };
        $self->{global}->{total}++;
    }
    #use Data::Dumper; print Dumper($self->{incidents}); exit 0;
}

    


#         if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
#             $scenario_detail->{infos}->{plugin_id} !~ /$self->{option_results}->{filter_type}/i) {
#             $self->{output}->output_add(long_msg => "skipping scenario '" . $_->{scenarioName} . "': no matching filter.", debug => 1);
#             next;
#         }

#         $self->{scenarios}->{ $_->{scenarioName} } = {
#             display => $_->{scenarioName},
#             global => {
#                 display => $_->{scenarioName},
#                 id => $_->{scenarioId},
#                 num_status => $_->{currentStatus},
#                 status => $status_mapping->{$_->{currentStatus}},
#             }
#         };

#         foreach my $kpi (@{$scenario_detail->{kpis}}) {
#             $self->{scenarios}->{ $_->{scenarioName} }->{global}->{$kpi->{label}} = $kpi->{value};
#         }
#         $self->{scenarios}->{ $_->{scenarioName} }->{steps_index}->{0} = 'Default';
#         if ($scenario_detail->{infos}->{info}->{hasStep}) {
#             foreach my $steps (@{$scenario_detail->{steps}}) {
#                 $self->{scenarios}->{ $_->{scenarioName} }->{steps_index}->{$steps->{index}} = $steps->{name};
#             }
#         }

#         foreach my $step_metrics (@{$scenario_detail->{results}}) {
#             my $exec_time = str2time($step_metrics->{planningTime}, 'GMT');
#             $self->{scenarios}->{ $_->{scenarioName} }->{steps}->{ $self->{scenarios}->{ $_->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} } }->{ $step_metrics->{metric} } = $step_metrics->{value};
#             $self->{scenarios}->{ $_->{scenarioName} }->{steps}->{ $self->{scenarios}->{ $_->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} } }->{last_exec} = POSIX::strftime('%d-%m-%Y %H:%M:%S', localtime($exec_time));
#             $self->{scenarios}->{ $_->{scenarioName} }->{steps}->{ $self->{scenarios}->{ $_->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} } }->{display} = $self->{scenarios}->{ $_->{scenarioName} }->{steps_index}->{ $step_metrics->{stepId} };
#         }

#     }
#     use Data::Dumper; print Dumper($self->{scenarios});
#     if (scalar(keys %{$self->{scenarios}}) <= 0) {
#         $self->{output}->add_option_msg(short_msg => "No scenario found");
#         $self->{output}->option_exit();
#     }


1;

__END__

=head1 MODE

Check IP Label Ekara scenarios.

=over 8

=item B<--filter-id>

Filter by monitor id (can be a regexp).

=item B<--filter-name>

Filter by monitor name (can be a regexp).

=item B<--filter-status>

Filter by numeric status (can be multiple).
0 => 'Unknown',
1 => 'Success',
2 => 'Failure',
3 => 'Aborted',
4 => 'No execution',
5 => 'No execution',
6 => 'Stopped',
7 => 'Excluded',
8 => 'Degraded'

Example: --filter-status='1,2'

=item B<--filter-type>

Filter by scenario type.
Can be: 'WEB', 'HTTPR', 'BROWSER PAGE LOAD'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'success-rate' (%) 'sla-availability' (%), 'performance' (ms).

=back

=cut
