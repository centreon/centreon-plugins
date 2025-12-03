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

package apps::controlm::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5;
use DateTime;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status: ' . $self->{result_values}->{status};
    if ($self->{result_values}->{extra_attrs} ne '') {
        $msg .= $self->{result_values}->{extra_attrs};
    }
    return $msg;
}

sub custom_long_output {
    my ($self, %options) = @_;

    return 'started since: ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});
}

sub custom_failed_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{application}, $self->{result_values}->{name}],
        value => $self->{result_values}->{failed},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of jobs ';
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "job '%s/%s' ",
        $options{instance_value}->{application},
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'jobs', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];

    $self->{maps_counters}->{jobs} = [
        { 
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /ended not ok/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'application' }, 
                    { name => 'type' }, { name => 'folder' }, { name => 'extra_attrs' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'long', type => 2, set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'application' }, 
                    { name => 'type' }, { name => 'folder' }, { name => 'elapsed' }
                ],
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
         { label => 'job-failed', nlabel => 'job.failed.count', display_ok => 0, set => {
                key_values => [
                    { name => 'failed' }, { name => 'name' }, { name => 'application' }
                ],
                output_template => 'failed: %s',
                closure_custom_perfdata => $self->can('custom_failed_perfdata')
            }
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'jobs-succeeded', nlabel => 'jobs.succeeded.count', set => {
                key_values => [ { name => 'succeeded' }, { name => 'total' } ],
                output_template => 'succeeded: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'jobs-failed', nlabel => 'jobs.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'jobs-executing', nlabel => 'jobs.executing.count', set => {
                key_values => [ { name => 'executing' }, { name => 'total' } ],
                output_template => 'executing: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'jobs-waiting',  nlabel => 'jobs.waiting.count', set => {
                key_values => [ { name => 'waiting' }, { name => 'total' } ],
                output_template => 'waiting: %s',
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
        'filter-application:s'  => { name => 'filter_application' },
        'filter-folder:s'       => { name => 'filter_folder' },
        'filter-type:s'         => { name => 'filter_type' },
        'filter-name:s'         => { name => 'filter_name' },
        'display-extra-attrs:s' => { name => 'display_extra_attrs' },
        'job-name:s'            => { name => 'job_name' },
        'timezone:s'            => { name => 'timezone' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $get_param = ['application=*'];
    if (defined($self->{option_results}->{job_name}) && $self->{option_results}->{job_name} ne '') {
        push @$get_param, 'jobname=' . $self->{option_results}->{job_name};
    } else {
        push @$get_param, 'jobname=*';
    }
    my $jobs = $options{custom}->request_api(
        endpoint => '/run/jobs/status',
        get_param => $get_param
    );

    my $current_time = time();
    $self->{global} = { total => 0, failed => 0, waiting => 0, succeeded => 0, executing => 0 };
    $self->{jobs} = {};
    foreach my $job (@{$jobs->{statuses}}) {
        next if (defined($self->{option_results}->{job_name}) && $self->{option_results}->{job_name} ne '' &&
            $job->{name} ne $self->{option_results}->{job_name});
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_folder}) && $self->{option_results}->{filter_folder} ne '' &&
            $job->{folder} !~ /$self->{option_results}->{filter_folder}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job->{type} !~ /$self->{option_results}->{filter_type}/);
        next if (defined($self->{option_results}->{filter_application}) && $self->{option_results}->{filter_application} ne '' &&
            $job->{application} !~ /$self->{option_results}->{filter_application}/);

        my $elapsed;
        # 20230214050004
        if ($job->{status} eq 'Executing' && $job->{startTime} =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/) {
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
        }

        my $failed = 0;
        $self->{global}->{total}++;
        if ($job->{status} eq 'Executing' ) {
            $self->{global}->{executing}++;
        } elsif ($job->{status} =~ /Ended Not OK/i) {
            $self->{global}->{failed}++;
            $failed = 1;
        } elsif ($job->{status} =~ /Ended OK/i) {
            $self->{global}->{succeeded}++;
        } elsif ($job->{status} =~ /Wait/i) {
            # Wait User — waiting for user confirmation.
            # Wait Resource — waiting on a resource to be available.
            # Wait Host — waiting on an agent or remote host to be available.
            # Wait Workload — waiting due to a workload limit.
            # Wait Condition — waiting for a condition.
            $self->{global}->{waiting}++;
        }

        my $extra_attrs = '';
        if (defined($self->{option_results}->{display_extra_attrs}) && $self->{option_results}->{display_extra_attrs} ne '') {
            $extra_attrs = $self->{option_results}->{display_extra_attrs};
            $extra_attrs =~ s/%\{(.*?)\}/$job->{$1}/g;
            $extra_attrs =~ s/%\((.*?)\)/$job->{$1}/g;
        }

        $self->{jobs}->{ $job->{jobId} } = { 
            name => $job->{name},
            folder => $job->{folder},
            application => $job->{application},
            type => $job->{type}, 
            status => lc($job->{status}),
            elapsed => $elapsed,
            failed => $failed,
            extra_attrs => $extra_attrs
        };
    }
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='failed'

=item B<--filter-folder>

Filter jobs by folder name (cannot be a regexp).

=item B<--filter-application>

Filter jobs by application name (cannot be a regexp).

=item B<--filter-type>

Filter jobs by type (cannot be a regexp).

=item B<--filter-name>

Filter jobs by job name (can be a regexp).

=item B<--job-name>

Check exact job name (no regexp).

=item B<--display-extra-attrs>

Display extra job attributes (example: --display-extra-attrs=', number of runs: %(numberOfRuns)').

=item B<--timezone>

Set date timezone.
Can use format: 'Europe/London' or '+0100'.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{name}, %{status}, %{application}, %{folder}, %{type}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /ended not ok/i').
You can use the following variables: %{name}, %{status}, %{application}, %{folder}, %{type}

=item B<--warning-long>

Set warning threshold for long jobs.
You can use the following variables: %{name}, %{status}, %{elapsed}, %{application}, %{folder}, %{type}

=item B<--critical-long>

Set critical threshold for long jobs.
You can use the following variables: %{name}, %{status}, %{elapsed}, %{application}, %{folder}, %{type}

=item B<--warning-jobs-succeeded>

Threshold.

=item B<--critical-jobs-succeeded>

Threshold.

=item B<--warning-jobs-failed>

Threshold.

=item B<--critical-jobs-failed>

Threshold.

=item B<--warning-jobs-executing>

Threshold.

=item B<--critical-jobs-executing>

Threshold.

=item B<--warning-jobs-waiting>

Threshold.

=item B<--critical-jobs-waiting>

Threshold.

=item B<--warning-job-failed>

Threshold.

=item B<--critical-job-failedg>

Threshold.

=back

=cut
