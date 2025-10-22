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

package apps::exense::step::restapi::mode::plans;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use POSIX; 
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_last_exec_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        instances => $self->{result_values}->{name},
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => $self->{result_values}->{lastExecSeconds} >= 0 ? floor($self->{result_values}->{lastExecSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastExecSeconds},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_last_exec_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{lastExecSeconds} >= 0 ? floor($self->{result_values}->{lastExecSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastExecSeconds},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_duration_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        instances => $self->{result_values}->{name},
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => floor($self->{result_values}->{durationSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_duration_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{durationSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_execution_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "result: %s, status: %s",
        $self->{result_values}->{result},
        $self->{result_values}->{status}
    );
}

sub plan_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking plan '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_plan_output {
    my ($self, %options) = @_;

        my $plan_name = defined $options{instance_value}->{name} ? $options{instance_value}->{name} : 'unknown';

    return sprintf("plan '%s' ", $plan_name);
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of plans ';
}

sub prefix_execution_output {
    my ($self, %options) = @_;

    return sprintf(
        "execution '%s' [env: %s] [started: %s] ",
        $options{instance_value}->{executionId},
        $options{instance_value}->{environment},
        $options{instance_value}->{started}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'plans', type => 3, cb_prefix_output => 'prefix_plan_output', cb_long_output => 'prefix_plan_output', indent_long_output => '    ', message_multiple => 'All plans are ok',
            group => [
                { name => 'exec_detect', type => 0 },
                { name => 'failed', type => 0 },
                { name => 'timers', type => 0, skipped_code => { -10 => 1 } },
                { name => 'executions', type => 1, cb_prefix_output => 'prefix_execution_output', message_multiple => 'executions are ok', display_long => 1, sort_method => 'num', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'plans-detected', display_ok => 0, nlabel => 'plans.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{exec_detect} = [
        { label => 'plan-executions-detected', nlabel => 'plan.executions.detected.count', set => {
                key_values => [ { name => 'detected' }, { name => 'name' } ],
                output_template => 'number of plan executions detected: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{failed} = [
        { label => 'plan-executions-failed-prct', nlabel => 'plan.executions.failed.percentage', set => {
                key_values => [ { name => 'failedPrct' }, { name => 'name' } ],
                output_template => 'number of failed executions: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{timers} = [
         { label => 'plan-execution-last', nlabel => 'plan.execution.last', set => {
                key_values  => [ { name => 'lastExecSeconds' }, { name => 'lastExecHuman' }, { name => 'name' } ],
                output_template => 'last execution %s',
                output_use => 'lastExecHuman',
                closure_custom_perfdata => $self->can('custom_last_exec_perfdata'),
                closure_custom_threshold_check => $self->can('custom_last_exec_threshold')
            }
        },
        { label => 'plan-running-duration', nlabel => 'plan.running.duration', set => {
                key_values  => [ { name => 'durationSeconds' }, { name => 'durationHuman' }, { name => 'name' } ],
                output_template => 'running duration %s',
                output_use => 'durationHuman',
                closure_custom_perfdata => $self->can('custom_duration_perfdata'),
                closure_custom_threshold_check => $self->can('custom_duration_threshold')
            }
        }
    ];

    $self->{maps_counters}->{executions} = [
        {
            label => 'plan-execution-status',
            type => 2,
            set => {
                key_values => [
                    { name => 'status' }, {name => 'result' }, { name => 'planName' }
                ],
                closure_custom_output => $self->can('custom_execution_status_output'),
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
        'filter-plan-id:s'     => { name => 'filter_plan_id' },
        'filter-plan-name:s'   => { name => 'filter_plan_name' },
        'filter-environment:s' => { name => 'filter_environment' },
        'since-timeperiod:s'   => { name => 'since_timeperiod' },
        'status-failed:s'      => { name => 'status_failed' },
        'only-last-execution'  => { name => 'only_last_execution' },
        'tenant-name:s'        => { name => 'tenant_name' },
        'timezone:s'           => { name => 'timezone' },
        'unit:s'               => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }

    if (!defined($self->{option_results}->{since_timeperiod}) || $self->{option_results}->{since_timeperiod} eq '') {
        $self->{option_results}->{since_timeperiod} = 86400;
    }

    if (!defined($self->{option_results}->{tenant_name}) || $self->{option_results}->{tenant_name} eq '') {
        $self->{option_results}->{tenant_name} = '[All]';
    }

    $self->{tz} = {};
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $self->{tz} = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    }

    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone}
eq '');

    if (!defined($self->{option_results}->{status_failed}) || $self->{option_results}->{status_failed} eq '') {
        $self->{option_results}->{status_failed} = '%{result} =~ /technical_error|failed|interrupted/i';
    }

    $self->{option_results}->{status_failed} =~ s/%\{(.*?)\}/\$values->{$1}/g;
    $self->{option_results}->{status_failed} =~ s/%\((.*?)\)/\$values->{$1}/g;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $status_filter = {};
    if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status}[0] ne '') {
        $status_filter->{statusFilter} = $self->{option_results}->{filter_status};
    }

    my $payload = $self->{option_results}->{tenant_name};
    $options{custom}->request(method => 'POST', endpoint => '/rest/tenants/current', query_form_post => $payload, skip_decode => 1);

    $payload = {
        skip => 0,
        limit => 4000000,
        filters => [
            {
                collectionFilter => { type => 'True', field => 'visible' }
            }
        ],
        'sort' => {
            'field' => 'attributes.name',
            'direction' => 'ASCENDING'
        }
    };
    eval {
        $payload = encode_json($payload);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    my $plans = $options{custom}->request(method => 'POST', endpoint => '/rest/table/plans', query_form_post => $payload);

    my $ctime = time();
    my $filterTime = ($ctime - $self->{option_results}->{since_timeperiod}) * 1000;
    
    $payload = {
        skip => 0,
        limit => 4000000,
        filters => [
            {
                collectionFilter => { type => 'Gte', field => 'startTime', value => $filterTime }
            }
        ],
        'sort' => {
            'field' => 'startTime',
            'direction' => 'DESCENDING'
        }
    };
    eval {
        $payload = encode_json($payload);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    my $executions = $options{custom}->request(method => 'POST', endpoint => '/rest/table/executions', query_form_post => $payload);

    $self->{global} = { detected => 0 };
    $self->{plans} = {};
    foreach my $plan (@{$plans->{data}}) {
        # skip plans created by keyword single execution
        next if (defined $plan->{visible} && $plan->{visible} =~ /false|0/);
        next if (defined($self->{option_results}->{filter_plan_id}) && $self->{option_results}->{filter_plan_id} ne '' &&
            $plan->{id} !~ /$self->{option_results}->{filter_plan_id}/);
        next if (defined($self->{option_results}->{filter_plan_name}) && $self->{option_results}->{filter_plan_name} ne '' &&
            $plan->{attributes}->{name} !~ /$self->{option_results}->{filter_plan_name}/);

        $self->{global}->{detected}++;

        $self->{plans}->{ $plan->{id} } = {
            name => $plan->{attributes}->{name},
            exec_detect => { detected => 0, name => $plan->{attributes}->{name} },
            failed => { failedPrct => 0, name => $plan->{attributes}->{name} },
            timers => {},
            executions => {}
        };

        my ($last_exec, $older_running_exec);
        my ($failed, $total) = (0, 0);
        my $i = 0;
        foreach my $plan_exec (@{$executions->{data}}) {
            next if (!defined($plan_exec->{planId}));
            next if ($plan_exec->{planId} ne $plan->{id});
            $plan_exec->{startTimeSec} = $plan_exec->{startTime} / 1000;
            next if ($plan_exec->{startTimeSec} < ($ctime - $self->{option_results}->{since_timeperiod}));
            next if (defined($self->{option_results}->{filter_environment}) && $self->{option_results}->{filter_environment} ne '' &&
                $plan_exec->{executionParameters}->{customParameters}->{env} !~ /$self->{option_results}->{filter_environment}/);

            # if the endTime is empty, we store this older running execution for later
            if (!defined($plan_exec->{endTime}) || $plan_exec->{endTime} eq '') {
                $older_running_exec = $plan_exec;
            }
            if (!defined($last_exec)) {
                $last_exec = $plan_exec;
            }

            $self->{plans}->{ $plan->{id} }->{exec_detect}->{detected}++;
            $failed++ if ($self->{output}->test_eval(test => $self->{option_results}->{status_failed}, values => { result => lc($plan_exec->{result}), status => lc($plan_exec->{status}) }));
            $total++;

            my $dt = DateTime->from_epoch(epoch => $plan_exec->{startTimeSec}, %{$self->{tz}});
            my $timeraised = sprintf(
                '%02d-%02d-%02dT%02d:%02d:%02d (%s)', $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second, $self->{option_results}->{timezone}
            );
            $self->{plans}->{ $plan->{id} }->{executions}->{$i} = {
                executionId => $plan_exec->{id},
                planName => $plan->{attributes}->{name},
                environment => $plan_exec->{executionParameters}->{customParameters}->{env},
                started => $timeraised,
                status => lc($plan_exec->{status}),
                result => lc($plan_exec->{result})
            };
            $i++;

            last if (defined($self->{option_results}->{only_last_execution}));
        }

        $self->{plans}->{ $plan->{id} }->{failed}->{failedPrct} = $total > 0 ? $failed * 100 / $total : 0;

        if (defined($last_exec)) {
            $self->{plans}->{ $plan->{id} }->{timers} = {
                name => $plan->{attributes}->{name},
                lastExecSeconds => defined($last_exec->{startTime}) ? $ctime - $last_exec->{startTimeSec} : -1,
                lastExecHuman =>  defined($last_exec->{startTime}) ? centreon::plugins::misc::change_seconds(value => $ctime -  $last_exec->{startTimeSec}) : 'never'
            };
        }

        if (defined($older_running_exec)) {
            my $duration = $ctime - $older_running_exec->{startTime};
            $self->{plans}->{ $plan->{name} }->{timers}->{durationSeconds} = $duration;
            $self->{plans}->{ $plan->{name} }->{timers}->{durationHuman} = centreon::plugins::misc::change_seconds(value => $duration);
        }
    }
}

1;

__END__

=head1 MODE

Check plans.

=over 8

=item B<--tenant-name>

Check plan of a tenant (default: '[All]').

=item B<--filter-plan-id>

Filter plans by plan ID.

=item B<--filter-plan-name>

Filter plans by plan name.

=item B<--filter-environment>

Filter plan executions by environment name.

=item B<--since-timeperiod>

Time period to get plans executions information (in seconds. default: 86400).

=item B<--only-last-execution>

Check only last plan execution.

=item B<--timezone>

Define timezone for start/end plan execution time (default is 'UTC').

=item B<--status-failed>

Expression to define status failed (default: '%{result} =~ /technical_error|failed|interrupted/i').

=item B<--unknown-plan-execution-status>

Set unknown threshold for last plan execution status.
You can use the following variables: %{status}, %{planName}

=item B<--warning-plan-execution-status>

Set warning threshold for last plan execution status.
You can use the following variables: %{status}, %{planName}

=item B<--critical-plan-execution-status>

Set critical threshold for last plan execution status.
You can use the following variables: %{status}, %{planName}

=item B<--warning-plans-detected>

Thresholds.

=item B<--critical-plans-detected>

Thresholds.

=item B<--warning-plan-executions-detected>

Thresholds.

=item B<--critical-plan-executions-detected>

Thresholds.

=item B<--warning-plan-executions-failed-prct>

Thresholds.

=item B<--critical-plan-executions-failed-prct>

Thresholds.

=item B<--warning-plan-execution-last>

Thresholds.

=item B<--critical-plan-execution-last>

Thresholds.

=item B<--warning-plan-running-duration>

Thresholds.

=item B<--critical-plan-running-duration>

Thresholds.


=back

=cut
