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

package cloud::azure::management::recovery::mode::backupjobsstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Status '%s' [Duration: %s]", $self->{result_values}->{status},
        $self->{result_values}->{duration});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{duration} = centreon::plugins::misc::change_seconds(value => $options{new_datas}->{$self->{instance} . '_duration'});
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Backup Jobs ";
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return "Backup Job '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', cb_init => 'skip_global' },
        { name => 'jobs', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-completed', set => {
                key_values => [ { name => 'completed' }  ],
                output_template => "completed : %s",
                perfdatas => [
                    { label => 'total_completed', value => 'completed', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-failed', set => {
                key_values => [ { name => 'failed' }  ],
                output_template => "failed : %s",
                perfdatas => [
                    { label => 'total_failed', value => 'failed', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-inprogress', set => {
                key_values => [ { name => 'inprogress' }  ],
                output_template => "in progress : %s",
                perfdatas => [
                    { label => 'total_inprogress', value => 'inprogress', template => '%d', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{jobs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'duration' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{jobs}}) == 1 ? return(1) : return(0);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "vault-name:s"          => { name => 'vault_name' },
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                    "filter-counters:s"     => { name => 'filter_counters' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{status} eq "Failed"' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource-group option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{vault_name}) || $self->{option_results}->{vault_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --vault-name option");
        $self->{output}->option_exit();
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        completed => 0, failed => 0, inprogress => 0,
    };
    $self->{jobs} = {};
    my $jobs = $options{custom}->azure_list_backup_jobs(
        vault_name => $self->{option_results}->{vault_name},
        resource_group => $self->{option_results}->{resource_group}
    );
    foreach my $job (@{$jobs}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $job->{properties}->{entityFriendlyName} !~ /$self->{option_results}->{filter_name}/);

        my $duration = $options{custom}->convert_duration(time_string => $job->{properties}->{duration});
        
        $self->{jobs}->{$job->{id}} = {
            display => $job->{properties}->{entityFriendlyName},
            status => $job->{properties}->{status},
            duration => $duration,
        };

        foreach my $status (keys %{$self->{global}}) {
            $self->{global}->{$status}++ if ($job->{properties}->{status} =~ /$status/i);
        }
    }
    
    if (scalar(keys %{$self->{jobs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No backup jobs found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check backup jobs status.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::recovery::plugin --custommode=azcli --mode=backup-jobs-status
--resource-group='MYRESOURCEGROUP' --vault-name='Loki' --filter-counters='^total-failed$' --critical-total-failed='0' --verbose

=over 8

=item B<--vault-name>

Set vault name (Required).

=item B<--resource-group>

Set resource group (Required).

=item B<--filter-name>

Filter job name (Can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-completed$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "Failed"').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-completed', 'total-failed', 'total-inprogress'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-completed', 'total-failed', 'total-inprogress'.

=back

=cut
