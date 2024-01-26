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
    if ($self->{result_values}->{status} =~ 'Open') {
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

    return sprintf("Incident #%s, Scenario '%s' ", $options{instance_value}->{display}, $options{instance_value}->{scenario_name});
}

sub prefix_triggers_output {
    my ($self, %options) = @_;

    return sprintf("  Site: '%s', last exec: %s, ", $options{instance_value}->{display}, $options{instance_value}->{last_exec});
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
        { label => 'incident-status',
            type => 2,
            warning_default => '',
            critical_default => '%{status} =~ "Open"',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'scenario_name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'incident-severity',
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
        { label => 'incident-duration', nlabel => 'ekara.incident.duration.seconds', set => {
                key_values => [ { name => 'duration' }, { name => 'start_time' }, { name => 'end_time' }, { name => 'status'} ],
                closure_custom_output => $self->can('custom_duration_output'),
		closure_custom_perfdata => sub { return 0; }
            }
        }
    ];

    $self->{maps_counters}->{triggers} = [
        { label => 'trigger-status',
            type => 2,
            warning_default => '',
            critical_default => '%{severity} =~ "Failure"',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' },
        'ignore-closed' => { name => 'ignore_closed' },
        'timeframe:s'   => { name => 'timeframe'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{timeframe} = defined($self->{option_results}->{timeframe})  && $self->{option_results}->{timeframe} ne '' ? $self->{option_results}->{timeframe} : '900';
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

    my $results = $options{custom}->request_api(
        endpoint => '/results-api/scenarios/status',
        method => 'POST',
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
    my $start_date = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($time - $self->{timeframe}));
    my $incidents;
    if (defined($scenarios_list->{scenarioIds})) {
        $incidents = $options{custom}->request_api(
            endpoint => '/results-api/incidents',
            method => 'POST',
            get_param => [
                'from=' . $start_date,
                'to=' . $end_date
            ],
            post_body => $scenarios_list
        );

    }

    $self->{global}->{total} = 0;

    if (ref($incidents) eq 'ARRAY' ) {
        foreach my $incident (@$incidents) {
            my $start_time = str2time($incident->{startTime}, 'GMT');
            my $end_time = defined($incident->{endTime}) ? str2time($incident->{endTime}, 'GMT') : time();
            next if (defined($self->{option_results}->{ignore_closed}) && defined($incident->{endTime}));

            my $incident_id = $incident->{ssr_id} . '_' . $incident->{scnName};
            $self->{incidents}->{$incident_id} = {
                display => $incident->{ssr_id},
                scenario_name => $incident->{scnName},
                incident => {
                    display => $incident->{ssr_id},
                    scenario_name => $incident->{scnName},
                    scenario_id => $incident->{scn_id},
                    status => defined($incident->{endTime}) ? 'Closed' : 'Open',
                    severity => $incident->{severity},
                    start_time => POSIX::strftime('%d-%m-%Y %H:%M:%S %Z', localtime($start_time)),
                    end_time => POSIX::strftime('%d-%m-%Y %H:%M:%S %Z', localtime($end_time)),
                    duration => $end_time - $start_time
                }
            };

            $self->{global}->{total}++;

            foreach my $trigger (@{$incident->{execList}}) {
                my $exec_time = str2time($trigger->{execTime}, 'GMT');
                $self->{incidents}->{$incident_id}->{triggers}->{ $trigger->{executionId} } = {
                    display => $trigger->{siteName},
                    status => $status_mapping->{$trigger->{status}},
                    last_exec => POSIX::strftime('%d-%m-%Y %H:%M:%S %Z', localtime($exec_time))
                }
            }
        }
    }
}

1;

__END__

=head1 MODE

Check IP Label Ekara incidents.

=over 8

=item B<--timeframe>

Set timeframe period in seconds. (default: 900)
Example: --timeframe='3600' will check the last hour

=item B<--filter-id>

Filter by monitor ID (can be a regexp).

=item B<--filter-name>

Filter by monitor name (can be a regexp).

=item B<--ignore-closed>

Ignore solved incidents within the timeframe.

=item B<--warning-incident-status>

Warning threshold for incident status (default: none).
Syntax: --warning-incident-status='%{status} =~ "xxx"'
Can be 'Open' or 'Closed'

=item B<--critical-incident-status>

Critical threshold for incident status (default: '%{status} =~ "Open"').
Syntax: --critical-incident-status='%{status} =~ "xxx"'
Can be 'Open' or 'Closed'

=item B<--warning-incident-severity>

Warning threshold for incident severity (default: none).
Syntax: --warning-incident-severity='%{severity} =~ "xxx"'

=item B<--critical-incident-severity>

Critical threshold for incident severity (default: '%{severity} =~ "Critical"').
Syntax: --critical-incident-severity='%{severity} =~ "xxx"'

=item B<--warning-trigger-status>

Warning threshold for trigger status (default: none).
Syntax: --warning-trigger-status='%{status} =~ "xxx"'
Can be 'Unknown', 'Success', 'Failure', 'Aborted', 'No execution',
'Stopped', 'Excluded', 'Degraded'

=item B<--critical-trigger-status>

Critical threshold for trigger status (default: '%{severity} =~ "Failure"').
Syntax: --critical-trigger-status='%{status} =~ "xxx"'
Can be 'Unknown', 'Success', 'Failure', 'Aborted', 'No execution',
'Stopped', 'Excluded', 'Degraded'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'warning-incidents-total' (count) 'critical-incidents-total' (count),
'warning-incident-duration' (s), 'critical-incident-duration' (s).

=back

=cut
