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

package apps::backup::veeam::vone::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_job_status_numeric = {
    unknown => 0,
    success => 1,
    none => 2,
    failed => 3,
    running => 4,
    warning => 5
};

sub custom_status_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'job.status.count',
        instances => [$self->{result_values}->{type}, $self->{result_values}->{name}],
        value => $map_job_status_numeric->{ $self->{result_values}->{status} },
        min => 0
    );
}

sub custom_duration_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'job.last.duration.seconds',
        unit => 's',
        instances => [$self->{result_values}->{type}, $self->{result_values}->{name}],
        value => $self->{result_values}->{duration_seconds},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of jobs ';
}

sub job_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking job '%s' [type: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
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
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'jobs', type => 3, cb_prefix_output => 'prefix_job_output', cb_long_output => 'job_long_output', indent_long_output => '    ', message_multiple => 'All jobs are ok',
            group => [
                { name => 'status', type => 0 },
                { name => 'metrics', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs-detected', display_ok => 0, nlabel => 'jobs.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'job-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'type' }
                ],
                output_template => 'status: %s',
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{metrics} = [
        { label => 'job-last-duration', set => {
                key_values => [ { name => 'duration_seconds' }, { name => 'duration_human' }, { name => 'name' }, { name => 'type' } ],
                output_template => 'last duration time: %s',
                output_use => 'duration_human',
                closure_custom_perfdata => $self->can('custom_duration_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-uid:s'            => { name => 'filter_uid' },
        'filter-name:s'           => { name => 'filter_name' },
        'filter-type:s'           => { name => 'filter_type' },
        'add-vm-replication-jobs' => { name => 'add_vm_replication_jobs' },
        'add-vm-backup-jobs'      => { name => 'add_vm_backup_jobs' },
        'add-backup-copy-jobs'    => { name => 'add_backup_copy_jobs' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{add_vm_replication_jobs}) &&
        !defined($self->{option_results}->{add_vm_backup_jobs}) &&
        !defined($self->{option_results}->{add_backup_copy_jobs})) {
        $self->{option_results}->{add_vm_replication_jobs} = 1;
    }
}

sub add_jobs {
    my ($self, %options) = @_;

    foreach my $job (@{$options{jobs}->{items}}) {
         next if (defined($self->{option_results}->{filter_uid}) && $self->{option_results}->{filter_uid} ne '' &&
            $job->{ $options{uid} } !~ /$self->{option_results}->{filter_uid}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{jobs}->{ $options{type} . '-' . $job->{name} } = {
            name => $job->{name},
            type => $options{type},
            status => {
                name => $job->{name},
                type => $options{type},
                status => lcfirst($job->{status})
            },
            metrics => {
                name => $job->{name},
                type => $options{type}
            }
        };
        if (defined($job->{lastRunDurationSec}) && $job->{lastRunDurationSec} =~ /[0-9]+/) {
            $self->{jobs}->{ $options{type} . '-' . $job->{name} }->{metrics}->{duration_seconds} = $job->{lastRunDurationSec};
            $self->{jobs}->{ $options{type} . '-' . $job->{name} }->{metrics}->{duration_human} = centreon::plugins::misc::change_seconds(
                value => $job->{lastRunDurationSec}
            );
        }

        $self->{global}->{detected}++;
    }
}

sub add_vm_replication_jobs {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_vm_replication_jobs}));
    return if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' && 
        $options{type} !~ /$self->{option_results}->{filter_type}/);

    my $jobs = $options{custom}->get_vm_replication_jobs();
    $self->add_jobs(jobs => $jobs, uid => 'vmReplicationJobUid', type => $options{type});
}

sub add_vm_backup_jobs {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_vm_backup_jobs}));
    return if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' && 
        $options{type} !~ /$self->{option_results}->{filter_type}/);

    my $jobs = $options{custom}->get_vm_backup_jobs();
    $self->add_jobs(jobs => $jobs, uid => 'vmBackupJobUid', type => $options{type});
}

sub add_backup_copy_jobs {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_backup_copy_jobs}));
    return if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' && 
        $options{type} !~ /$self->{option_results}->{filter_type}/);

    my $jobs = $options{custom}->get_backup_copy_jobs();
    $self->add_jobs(jobs => $jobs, uid => 'backupCopyJobUid', type => $options{type});
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0 };
    $self->{jobs} = {};
    $self->add_backup_copy_jobs(custom => $options{custom}, type => 'backupCopy');
    $self->add_vm_backup_jobs(custom => $options{custom}, type => 'vmBackup');
    $self->add_vm_replication_jobs(custom => $options{custom}, type => 'vmReplication');
}

1;

__END__

=head1 MODE

Check backup jobs.

=over 8

=item B<--filter-uid>

Filter jobs by UID (can be a regexp).

=item B<--filter-name>

Filter jobs by name (can be a regexp).

=item B<--filter-type>

Filter jobs by type (can be a regexp).

=item B<--unknown-job-status>

Define the conditions to match for the status to be UNKOWN (default: '%{state} =~ /unknown/i').
You can use the following variables: %{status}, %{name}, %{type}

=item B<--warning-job-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /warning/i').
You can use the following variables: %{status}, %{name}, %{type}

=item B<--critical-job-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /failed/i').
You can use the following variables: %{status}, %{name}, %{type}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'jobs-detected', 'job-last-duration'.

=back

=cut
