#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::backup::commvault::commserve::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub custom_long_output {
    my ($self, %options) = @_;
    
    return 'started since: ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return "Job '" . $options{instance_value}->{display} . "' [type: " . $options{instance_value}->{type} . "] " ;
}

sub policy_long_output {
    my ($self, %options) = @_;

    return "Checking policy '" . $options{instance_value}->{display} . "'";
}

sub prefix_policy_output {
    my ($self, %options) = @_;

    return "Policy '" . $options{instance_value}->{display} . "' ";
}

sub custom_long_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};

    return -11 if ($self->{result_values}->{status} !~ /running|queued|waiting/i);

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'policy', type => 2,
          cb_prefix_output        => 'prefix_policy_output', 
          cb_long_output          => 'policy_long_output',
          display_counter_problem => { nlabel => 'jobs.problems.current.count', min => 0 },
          message_multiple        => 'All policies are ok',
          group => [ { name => 'job', cb_prefix_output => 'prefix_job_output', skipped_code => { -11 => 1 } } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs-total', nlabel => 'jobs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total jobs: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{job} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /abnormal/i',
            critical_default => '%{status} =~ /errors|failed/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'type' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'long', type => 2, set => {
                key_values => [
                    { name => 'status' }, { name => 'display' }, { name => 'elapsed' }, { name => 'type' }
                ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-policy-name:s'  => { name => 'filter_policy_name' },
        'filter-policy-id:s'    => { name => 'filter_policy_id' },
        'filter-type:s'         => { name => 'filter_type' },
        'filter-client-group:s' => { name => 'filter_client_group' },
        'filter-client-name:s'  => { name => 'filter_client_name' },
        'timeframe:s'           => { name => 'timeframe' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'commvault_commserve_' . $options{custom}->get_connection_infos() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_policy_name}) ? md5_hex($self->{option_results}->{filter_policy_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_policy_id}) ? md5_hex($self->{option_results}->{filter_policy_id}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_type}) ? md5_hex($self->{option_results}->{filter_type}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_client_group}) ? md5_hex($self->{option_results}->{filter_client_group}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_client_name}) ? md5_hex($self->{option_results}->{filter_client_name}) : md5_hex('all'));
    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    $last_timestamp = time() - 300 if (!defined($last_timestamp));

    my $lookup_time = time() - $last_timestamp;
    if (defined($self->{option_results}->{timeframe}) && $self->{option_results}->{timeframe} =~ /(\d+)/) {
        $lookup_time = $1;
    }

    # Also we get Pending/Waiting/Running jobs with that
    my $results = $options{custom}->request(
        endpoint => '/Job?completedJobLookupTime=' . $lookup_time
    );

    $self->{global} = { total => 0 };
    $self->{policy} = {};

    my $jobs_checked = {};
    my $current_time = time();
    foreach (@{$results->{jobs}}) {
        my $job = $_->{jobSummary};
        next if (defined($jobs_checked->{ $job->{jobId} }));
        $jobs_checked->{ $job->{jobId} } = 1;

        my $policy_name = defined($job->{storagePolicy}->{storagePolicyName}) && $job->{storagePolicy}->{storagePolicyName} ne '' ? $job->{storagePolicy}->{storagePolicyName} : 'unknown'; 
        my $policy_id = defined($job->{storagePolicy}->{storagePolicyId}) && $job->{storagePolicy}->{storagePolicyId} ne '' ? $job->{storagePolicy}->{storagePolicyId} : 'unknown'; 
        # when the job is running, end_time = 0

        if (defined($self->{option_results}->{filter_policy_name}) && $self->{option_results}->{filter_policy_name} ne '' &&
            $policy_name !~ /$self->{option_results}->{filter_policy_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $policy_name . "/" . $job->{jobId} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_policy_id}) && $self->{option_results}->{filter_policy_id} ne '' &&
            $policy_id !~ /$self->{option_results}->{filter_policy_id}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $policy_name . "/" . $job->{jobId} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job->{jobType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $policy_name . "/" . $job->{jobId} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_client_name}) && $self->{option_results}->{filter_client_name} ne '' &&
            $job->{destClientName} !~ /$self->{option_results}->{filter_client_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $policy_name . "/" . $job->{jobId} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($job->{clientGroups}) && defined($self->{option_results}->{filter_client_name}) && $self->{option_results}->{filter_client_name} ne '') {
            my $matched = 0;
            foreach (@$job->{clientGroups}) {
                if ($_->{clientGroupName} =~ /$self->{option_results}->{filter_client_group}/) {
                    $matched = 1;
                    last;
                }
            }

            if ($matched == 0) {
                $self->{output}->output_add(long_msg => "skipping job '" . $policy_name . "/" . $job->{jobId} . "': no matching filter type.", debug => 1);
                next;
            }
        }

        $self->{policy}->{$policy_name} = { job => {}, display => $policy_name } if (!defined($self->{policy}->{$policy_name}));
        my $elapsed_time = $current_time - $job->{jobStartTime};
        $self->{policy}->{$policy_name}->{job}->{ $job->{jobId} } = {
            display => $job->{jobId},
            elapsed => $elapsed_time, 
            status => $job->{status},
            type => $job->{jobType}
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-policy-name>

Filter jobs by policy name (can be a regexp).

=item B<--filter-policy-id>

Filter jobs by policy id (can be a regexp).

=item B<--filter-type>

Filter jobs by type (can be a regexp).

=item B<--filter-client-name>

Filter jobs by client name (can be a regexp).

=item B<--filter-client-group>

Filter jobs by client groups (can be a regexp).

=item B<--timeframe>

Set timeframe in seconds (E.g '3600' to check last 60 minutes).

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /abnormal/i')
Can used special variables like: %{display}, %{status}, %{type}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /errors|failed/i').
Can used special variables like: %{display}, %{status}, %{type}

=item B<--warning-long>

Set warning threshold for long jobs.
Can used special variables like: %{display}, %{status}, %{elapsed}, %{type}

=item B<--critical-long>

Set critical threshold for long jobs.
Can used special variables like: %{display}, %{status}, %{elapsed}, %{type}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'jobs-total'.

=back

=cut
