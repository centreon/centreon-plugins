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

package cloud::talend::tmc::mode::plans;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5;
use DateTime;
use POSIX;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use centreon::plugins::statefile;

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

sub plan_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking plan '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_plan_output {
    my ($self, %options) = @_;

    return sprintf(
        "plan '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of plans ';
}

sub prefix_execution_output {
    my ($self, %options) = @_;

    return sprintf(
        "execution '%s' [started: %s] ",
        $options{instance_value}->{executionId},
        $options{instance_value}->{started}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'plans', type => 3, cb_prefix_output => 'prefix_plan_output', cb_long_output => 'plan_long_output', indent_long_output => '    ', message_multiple => 'All plans are ok',
            group => [
                { name => 'failed', type => 0 },
                { name => 'timers', type => 0, skipped_code => { -10 => 1 } },
                { name => 'executions', type => 1, cb_prefix_output => 'prefix_execution_output', message_multiple => 'executions are ok', display_long => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'plans-executions-detected', display_ok => 0, nlabel => 'plans.executions.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'executions detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{failed} = [
        { label => 'plan-executions-failed-prct', nlabel => 'plan.executions.failed.percentage', set => {
                key_values => [ { name => 'failedPrct' } ],
                output_template => 'number of failed executions: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
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
            label => 'execution-status',
            type => 2,
            critical_default => '%{status} =~ /execution_failed/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'planName' }
                ],
                output_template => "status: %s",
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
        'plan-id:s'          => { name => 'plan_id' },
        'environment-name:s' => { name => 'environment_name' },
        'since-timeperiod:s' => { name => 'since_timeperiod' },
        'unit:s'             => { name => 'unit', default => 's' }
    });

    $self->{cache_exec} = centreon::plugins::statefile->new(%options);

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

    $self->{cache_exec}->check_options(option_results => $self->{option_results}, default_format => 'json');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $environments = $options{custom}->get_environments();
    my $environmentId;
    if (defined($self->{option_results}->{environment_name}) && $self->{option_results}->{environment_name} ne '') {
        foreach (@$environments) {
            if ($_->{name} eq $self->{option_results}->{environment_name}) {
                $environmentId = $_->{id};
                last;
            }
        }

        if (!defined($environmentId)) {
            $self->{output}->add_option_msg(short_msg => 'unknown environment name ' . $self->{option_results}->{environment_name});
            $self->{output}->option_exit();
        }
    }

    my $plans_config = $options{custom}->get_plans_config();

    my $to = time();
    my $plans_exec = $options{custom}->get_plans_execution(
        from => ($to - $self->{option_results}->{since_timeperiod}) * 1000,
        to => $to * 1000,
        environmentId => $environmentId,
        planId => $self->{option_results}->{plan_id}
    );

    $self->{cache_exec}->read(statefile => 'talend_tmc_' . $self->{mode} . '_' . 
        Digest::MD5::md5_hex(
            (defined($self->{option_results}->{plan_id}) ? $self->{option_results}->{plan_id} : '') . '_' .
            (defined($self->{option_results}->{environment_name}) ? $self->{option_results}->{environment_name} : '')
        )
    );
    my $ctime = time();
    my $last_exec_times = $self->{cache_exec}->get(name => 'plans');
    $last_exec_times = {} if (!defined($last_exec_times));    

    $self->{global} = { detected => 0 };
    $self->{plans} = {};
    foreach my $plan (@$plans_config) {
        next if (defined($self->{option_results}->{plan_id}) && $self->{option_results}->{plan_id} ne '' && $plan->{executable} ne $self->{option_results}->{plan_id});
        next if (defined($environmentId) && $plan->{workspace}->{environment}->{id} ne $environmentId);

        $self->{plans}->{ $plan->{name} } = {
            name => $plan->{name},
            timers => {},
            executions => {}
        };

        my ($last_exec, $older_running_exec);
        my ($failed, $total) = (0, 0);
        foreach my $plan_exec (@$plans_exec) {
            next if ($plan_exec->{planId} ne $plan->{executable});

            if (!defined($plan_exec->{finishTimestamp})) {
                $older_running_exec = $plan_exec;
            }
            if (!defined($last_exec)) {
                $last_exec = $plan_exec;
            }

            $self->{global}->{detected}++;
            $failed++ if ($plan_exec->{status} =~ /execution_failed/);
            $total++;
        }

        $self->{plans}->{ $plan->{name} }->{failed} = {
            failedPrct => $total > 0 ? $failed * 100 / $total : 0
        };

        if (defined($last_exec)) {
            $self->{plans}->{ $plan->{name} }->{executions}->{ $last_exec->{executionId} } = {
                executionId => $last_exec->{executionId},
                planName => $plan->{name},
                started => $last_exec->{startTimestamp},
                status => $last_exec->{status}
            };

            $last_exec->{startTimestamp} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
            my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
            $last_exec_times->{ $plan->{name} } = $dt->epoch();
        }

        $self->{plans}->{ $plan->{name} }->{timers} = {
            name => $plan->{name},
            lastExecSeconds => defined($last_exec_times->{ $plan->{name} }) ? $ctime - $last_exec_times->{ $plan->{name} } : -1,
            lastExecHuman => 'never'
        };
        if (defined($last_exec_times->{ $plan->{name} })) {
            $self->{plans}->{ $plan->{name} }->{timers}->{lastExecHuman} = centreon::plugins::misc::change_seconds(value => $ctime -  $last_exec_times->{ $plan->{name} });
        }

        if (defined($older_running_exec)) {
            $older_running_exec->{startTimestamp} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
            my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
            my $duration = $ctime - $dt->epoch();
            $self->{plans}->{ $plan->{name} }->{timers}->{durationSeconds} = $duration;
            $self->{plans}->{ $plan->{name} }->{timers}->{durationHuman} = centreon::plugins::misc::change_seconds(value => $duration);
        }
    }

    $self->{cache_exec}->write(data => {
        plans => $last_exec_times
    });
}

1;

__END__

=head1 MODE

Check plans.

=over 8

=item B<--plan-id>

Plan filter.

=item B<--environment-name>

Environment filter.

=item B<--since-timeperiod>

Time period to get plans execution informations (in seconds. Default: 86400). 

=item B<--unit>

Select the time unit for the last execution time thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is secondss.

=item B<--unknown-execution-status>

Set unknown threshold for last plan execution status.
You can use the following variables: %{status}, %{planName}

=item B<--warning-execution-status>

Set warning threshold for last plan execution status.
You can use the following variables: %{status}, %{planName}

=item B<--critical-execution-status>

Set critical threshold for last plan execution status (default: '{status} =~ /execution_failed/i').
You can use the following variables: %{status}, %{planName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'plans-executions-detected', 'plan-executions-failed-prct',
'plan-execution-last', 'plan-running-duration'.

=back

=cut
