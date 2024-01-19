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

package apps::vtom::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5;
use DateTime;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status: ' . $self->{result_values}->{status};
    if ($self->{result_values}->{message} ne '') {
        $msg .= ' [message: ' . $self->{result_values}->{message} . ']';
    }

    return $msg;
}

sub custom_long_output {
    my ($self, %options) = @_;

    return 'started since: ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});
}

sub custom_long_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{environment} = $options{new_datas}->{$self->{instance} . '_environment'};
    $self->{result_values}->{application} = $options{new_datas}->{$self->{instance} . '_application'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};

    return -11 if ($self->{result_values}->{status} !~ /Running/i);

    return 0;
}

sub custom_success_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '%',
        instances => [$self->{result_values}->{environment}, $self->{result_values}->{application}, $self->{result_values}->{name}],
        value => $self->{result_values}->{success},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => 100
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of jobs ';
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "job '%s/%s/%s' ",
        $options{instance_value}->{environment},
        $options{instance_value}->{application},
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'jobs', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok', , skipped_code => { -10 => 1, -11 => 1 } }
    ];
    
    $self->{maps_counters}->{jobs} = [
        { 
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /Error/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'environment' }, 
                    { name => 'application' }, { name => 'exit_code' }, { name => 'message' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'long', type => 2, set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'environment' }, 
                    { name => 'application' }, { name => 'elapsed' }
                ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
         { label => 'success-prct', nlabel => 'job.success.percentage', set => {
                key_values => [
                    { name => 'success' }, { name => 'name' },
                    { name => 'environment' }, { name => 'application' }
                ],
                output_template => 'success: %.2f %%',
                closure_custom_perfdata => $self->can('custom_success_perfdata')
            }
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'running', nlabel => 'jobs.running.count', set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'running: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'errors', nlabel => 'jobs.errors.count', set => {
                key_values => [ { name => 'error' }, { name => 'total' } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'waiting',  nlabel => 'jobs.waiting.count', set => {
                key_values => [ { name => 'waiting' }, { name => 'total' } ],
                output_template => 'waiting: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'finished', nlabel => 'jobs.finished.count', set => {
                key_values => [ { name => 'finished' }, { name => 'total' } ],
                output_template => 'finished: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'notscheduled', nlabel => 'jobs.notscheduled.count', set => {
                key_values => [ { name => 'notscheduled' }, { name => 'total' } ],
                output_template => 'not scheduled: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'descheduled', nlabel => 'jobs.descheduled.count', set => {
                key_values => [ { name => 'descheduled' }, { name => 'total' } ],
                output_template => 'descheduled: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
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
        'filter-application:s' => { name => 'filter_application' },
        'filter-environment:s' => { name => 'filter_environment' },
        'filter-name:s'        => { name => 'filter_name' },
        'timezone:s'           => { name => 'timezone' }
    });

    $self->{cache_status} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{cache_status}->check_options(%options);
}

sub get_success {
    my ($self, %options) = @_;

    if (!defined($options{history}->{ $options{id} })) {
        $options{history}->{ $options{id} } = { lastEndDateTime => '', status => [] };
    }

    if ($options{job}->{status} =~ /finished|errors/i) {
        if ($options{history}->{ $options{id} }->{lastEndDateTime} ne $options{job}->{endDateTime}) {
            push @{$options{history}->{ $options{id} }->{status}}, $options{job}->{status};
            $options{history}->{ $options{id} }->{lastEndDateTime} = $options{job}->{endDateTime};
        }
    }

    return undef if (scalar(@{$options{history}->{ $options{id} }->{status}}) <= 0);
    shift @{$options{history}->{ $options{id} }->{status}}
        if (scalar(@{$options{history}->{ $options{id} }->{status}}) > 10);
    my $success = 0;
    foreach (@{$options{history}->{ $options{id} }->{status}}) {
        $success++ if (/finished/i);
    }

    $success = $success * 100 / scalar(@{$options{history}->{ $options{id} }->{status}});
    return $success;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $jobs = $options{custom}->get_jobs();

    $self->{cache_status}->read(
        statefile => 'vtom_' . Digest::MD5::md5_hex(
            $options{custom}->get_connection_info() . '_' . 
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_application}) ? $self->{option_results}->{filter_application} : '') . '_' .
            (defined($self->{option_results}->{filter_environment}) ? $self->{option_results}->{filter_environment} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '')
        )
    );
    my $history = $self->{cache_status}->get(name => 'history');
    $history = {} if (!defined($history));

    my $current_time = time();
    $self->{global} = { total => 0, running => 0, waiting => 0, finished => 0, error => 0, notscheduled => 0, descheduled => 0 };
    $self->{jobs} = {};
    foreach my $job (@$jobs) {
        my $id = $job->{environment} . '/' . $job->{application} . '/' . $job->{name};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $job->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_application}) && $self->{option_results}->{filter_application} ne '' &&
            $job->{application} !~ /$self->{option_results}->{filter_application}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $job->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_environment}) && $self->{option_results}->{filter_environment} ne '' &&
            $job->{environment} !~ /$self->{option_results}->{filter_environment}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $job->{name} . "': no matching filter.", debug => 1);
            next;
        }

        my $elapsed;
        # 2022-01-18 01:08:33
        if (defined($job->{beginDateTime}) && $job->{beginDateTime} =~ /^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/) {
            my $tz = {};
            if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
                $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
            }
            my $dt = DateTime->new(
                year => $1,
                month => $2,
                day => $3,
                hour => $4,
                minute => $5,
                second => $6,
                %$tz
            );
            $elapsed = $current_time - $dt->epoch();
        } elsif (defined($job->{duration})) {
            $elapsed = $job->{duration};
        }

        my $message = defined($job->{message}) ? $job->{message} : '';
        $message =~ s/\|/-/msg;

        my $success = $self->get_success(
            id => $id,
            job => $job,
            history => $history
        );

        $self->{global}->{total}++;
        $self->{global}->{ lc($job->{status}) }++;
        $self->{jobs}->{$id} = { 
            name => $job->{name},
            application => $job->{application},
            environment => $job->{environment}, 
            status => lc($job->{status}),
            message => $message,
            exit_code => defined($job->{returnCode}) ? $job->{returnCode} : '-',
            elapsed => $elapsed,
            success => $success
        };
    }

    $self->{cache_status}->write(data => $history);
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='total-error'

=item B<--filter-environment>

Filter environment name (cannot be a regexp).

=item B<--filter-application>

Filter application name (cannot be a regexp).

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--timezone>

Set date timezone.
Can use format: 'Europe/London' or '+0100'.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: -)
You can use the following variables: %{name}, %{status}, %{exit_code}, %{message}, %{environment}, %{application}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{exit_code} =~ /Error/i').
You can use the following variables: %{name}, %{status}, %{exit_code}, %{message}, %{environment}, %{application}

=item B<--warning-long>

Set warning threshold for long jobs (default: none)
You can use the following variables: %{name}, %{status}, %{elapsed}, %{application}

=item B<--critical-long>

Set critical threshold for long jobs (default: none).
You can use the following variables: %{name}, %{status}, %{elapsed}, %{application}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'running', 'errors', 'waiting',
'finished', 'notscheduled', 'descheduled',
'success-prct'.

=back

=cut
