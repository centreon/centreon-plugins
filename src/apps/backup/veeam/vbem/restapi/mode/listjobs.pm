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

package apps::backup::veeam::vbem::restapi::mode::listjobs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeframe:s' => { name => 'timeframe' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{timeframe}) || $self->{option_results}->{timeframe} eq '') {
        $self->{option_results}->{timeframe} = 86400;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = {};
    my $jobs_exec = $options{custom}->cache_backup_job_session(timeframe => $self->{option_results}->{timeframe});
    my $jobs_replica = $options{custom}->get_replica_job_session(timeframe => $self->{option_results}->{timeframe});

    foreach my $job (@{$jobs_exec->{entities}->{backupjobsessions}->{backupjobsessions}}) {
        next if (defined($results->{ $job->{jobuid} }));

        $results->{ $job->{jobuid} } = {
            jobName => $job->{jobname},
            jobType => $job->{jobtype}
        }
    }

    foreach my $job (@{$jobs_replica->{entities}->{replicajobsessions}->{replicajobsessions}}) {
        next if (defined($results->{ $job->{jobuid} }));

        $results->{ $job->{jobuid} } = {
            jobName => $job->{jobname},
            jobType => $job->{jobtype}
        }
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $uid (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[uid: %s][jobName: %s][jobType: %s]',
                $uid,
                $results->{$uid}->{jobName},
                $results->{$uid}->{jobType}
            )
        );
    }
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List jobs:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['uid', 'jobName', 'jobType']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $uid (keys %$results) {
        $self->{output}->add_disco_entry(
            uid => $uid,
            jobName => $results->{$uid}->{jobName},
            jobType => $results->{$uid}->{jobType}
        );
    }
}

1;

__END__

=head1 MODE

List jobs.

=over 8

=item B<--timeframe>

Timeframe to get BackupJobSession and ReplicaJobSession (in seconds. Default: 86400).

=back

=cut
