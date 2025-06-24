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

package apps::backup::veeam::vone::restapi::mode::listjobs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub add_jobs {
    my ($self, %options) = @_;

    foreach my $job (sort { $a->{name} cmp $b->{name} } @{$options{jobs}->{items}}) {
        push @{$self->{results}}, { uid => $job->{ $options{uid} }, name => $job->{name}, type => $options{type}, status => lc($job->{status}) };
    }
}

sub add_vm_replication_jobs {
    my ($self, %options) = @_;

    my $jobs = $options{custom}->get_vm_replication_jobs(disable_cache => 1);
    $self->add_jobs(jobs => $jobs, uid => 'vmReplicationJobUid', type => $options{type});
}

sub add_vm_backup_jobs {
    my ($self, %options) = @_;

    my $jobs = $options{custom}->get_vm_backup_jobs(disable_cache => 1);
    $self->add_jobs(jobs => $jobs, uid => 'vmBackupJobUid', type => $options{type});
}

sub add_backup_copy_jobs {
    my ($self, %options) = @_;

    my $jobs = $options{custom}->get_backup_copy_jobs(disable_cache => 1);
    $self->add_jobs(jobs => $jobs, uid => 'backupCopyJobUid', type => $options{type});
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = [];

    $self->add_backup_copy_jobs(custom => $options{custom}, type => 'backupCopy');
    $self->add_vm_backup_jobs(custom => $options{custom}, type => 'vmBackup');
    $self->add_vm_replication_jobs(custom => $options{custom}, type => 'vmReplication');
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{results}}) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[uid: %s][name: %s][type: %s][status: %s]',
                $_->{uid},
                $_->{name},
                $_->{type},
                $_->{status}
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

    $self->{output}->add_disco_format(elements => ['uid', 'name', 'type', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{results}}) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List jobs.

=over 8

=back

=cut
