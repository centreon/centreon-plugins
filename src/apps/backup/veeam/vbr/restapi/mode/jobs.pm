#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::veeam::vbr::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded value_of/;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s, last result: %s',
        $self->{result_values}->{status},
        $self->{result_values}->{last_result}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of jobs ';
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return sprintf(
        "job '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'jobs', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs-detected', nlabel => 'jobs.detected.count', unknown_default => '@0', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
    foreach my $result ('success', 'warning', 'failed') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'jobs-' . $result, nlabel => 'jobs.' . $result . '.count', set => {
                key_values => [ { name => $result }, { name => 'detected' } ],
                output_template => $result . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'detected' }
                ]
            }
        };
    }

    $self->{maps_counters}->{jobs} = [
        {
            label => 'job-status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{last_result} =~ /warning/i and %{status} !~ /disabled/i',
            critical_default => '%{last_result} =~ /failed/i and %{status} !~ /disabled/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'last_result' }, { name => 'name' }, { name => 'type' }, { name => 'workload' }
                ],
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
        'include-name:s'   => { name => 'include_name', default => '' },
        'exclude-name:s'   => { name => 'exclude_name', default => '' },
        'include-type:s'   => { name => 'include_type', default => '' },
        'exclude-type:s'   => { name => 'exclude_type', default => '' },
        'include-status:s' => { name => 'include_status', default => '' },
        'exclude-status:s' => { name => 'exclude_status', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $jobs = $options{custom}->get_job_states();

    $self->{global} = { detected => 0, success => 0, warning => 0, failed => 0 };
    $self->{jobs} = {};

    foreach my $job (@$jobs) {
        next if is_excluded($job->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
            || is_excluded($job->{type}, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output})
            || is_excluded($job->{status}, $self->{option_results}->{include_status}, $self->{option_results}->{exclude_status}, output => $self->{output});

        my $last_result = value_of($job, '->{lastResult}', 'None');
        $self->{jobs}->{ $job->{id} } = {
            id => $job->{id},
            name => $job->{name},
            type => value_of($job, '->{type}', 'Unknown'),
            workload => value_of($job, '->{workload}', '-'),
            status => value_of($job, '->{status}', 'Unknown'),
            last_result => $last_result
        };

        $self->{global}->{detected}++;
        $self->{global}->{ lc($last_result) }++
            if defined($self->{global}->{ lc($last_result) });
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'type', 'workload', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $job (sort { $a->{name} cmp $b->{name} } values %{$self->{jobs}}) {
        $self->{output}->add_disco_entry(
            id => $job->{id},
            name => $job->{name},
            type => $job->{type},
            workload => $job->{workload},
            status => $job->{status}
        );
    }
}

1;

__END__

=head1 MODE

Check backup jobs states and last results.

=over 8

=item B<--include-name>

Filter jobs by name (can be a regexp).

=item B<--exclude-name>

Exclude jobs by name (can be a regexp).

=item B<--include-type>

Filter jobs by type (can be a regexp). Example: C<VSphereBackup>, C<BackupCopy>, C<LinuxAgentBackup>.

=item B<--exclude-type>

Exclude jobs by type (can be a regexp).

=item B<--include-status>

Filter jobs by current status (can be a regexp). Example: C<Running>, C<Stopped>, C<Disabled>.

=item B<--exclude-status>

Exclude jobs by current status (can be a regexp).

=item B<--warning-job-status>

Define the conditions to match for the status to be WARNING (default: '%{last_result} =~ /warning/i and %{status} !~ /disabled/i').
You can use the following variables: %{status}, %{last_result}, %{name}, %{type}, %{workload}

=item B<--critical-job-status>

Define the conditions to match for the status to be CRITICAL (default: '%{last_result} =~ /failed/i and %{status} !~ /disabled/i').
You can use the following variables: %{status}, %{last_result}, %{name}, %{type}, %{workload}

=item B<--warning-jobs-detected>

Threshold.

=item B<--critical-jobs-detected>

Threshold.

=item B<--warning-jobs-success>

Threshold.

=item B<--critical-jobs-success>

Threshold.

=item B<--warning-jobs-warning>

Threshold.

=item B<--critical-jobs-warning>

Threshold.

=item B<--warning-jobs-failed>

Threshold.

=item B<--critical-jobs-failed>

Threshold.

=back

=cut
