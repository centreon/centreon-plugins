#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::mode::tasks;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name         => 'global',
            type         => 0,
            message_separator => ' ',
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'running',
            nlabel => 'tasks.running.count',
            set    => {
                key_values      => [ { name => 'running' } ],
                output_template => 'running: %d',
                perfdatas       => [
                    {
                        template => '%d',
                        min      => 0,
                    }
                ]
            }
        },
        {
            label  => 'succeeded',
            nlabel => 'tasks.succeeded.count',
            set    => {
                key_values      => [ { name => 'succeeded' } ],
                output_template => 'succeeded: %d',
                perfdatas       => [
                    {
                        template => '%d',
                        min      => 0,
                    }
                ]
            }
        },
        {
            label  => 'failed',
            nlabel => 'tasks.failed.count',
            set    => {
                key_values      => [ { name => 'failed' } ],
                output_template => 'failed: %d',
                perfdatas       => [
                    {
                        template => '%d',
                        min      => 0,
                    }
                ]
            }
        },
        {
            label  => 'aborted',
            nlabel => 'tasks.aborted.count',
            set    => {
                key_values      => [ { name => 'aborted' } ],
                output_template => 'aborted: %d',
                perfdatas       => [
                    {
                        template => '%d',
                        min      => 0,
                    }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_tasks();
    my $entities = $result->{entities} // [];

    my %counts = ( running => 0, succeeded => 0, failed => 0, aborted => 0 );

    for my $task (@{$entities}) {
        # Prism v2.0 task statuses start with a 'k' prefix (e.g. kRunning, kSucceeded).
        # Normalize to lowercase without prefix for consistent matching.
        my $status = $task->{progress_status} // '';
        $status =~ s/^k//i;
        $status = lc($status);

        if    ($status eq 'running')   { $counts{running}++   }
        elsif ($status eq 'succeeded') { $counts{succeeded}++ }
        elsif ($status eq 'failed')    { $counts{failed}++    }
        elsif ($status eq 'aborted')   { $counts{aborted}++   }
    }

    $self->{global} = \%counts;
}

1;

__END__

=head1 MODE

Monitor Nutanix background task counts through Prism REST API.

Returns global counts for running, succeeded, failed and aborted tasks
from the last 100 tasks (top-level tasks only; subtasks excluded).

=over 8

=item B<--warning-running>

Warning threshold for running task count.

=item B<--critical-running>

Critical threshold for running task count.

=item B<--warning-succeeded>

Warning threshold for succeeded task count.

=item B<--critical-succeeded>

Critical threshold for succeeded task count.

=item B<--warning-failed>

Warning threshold for failed task count. Example: C<--critical-failed=1>

=item B<--critical-failed>

Critical threshold for failed task count.

=item B<--warning-aborted>

Warning threshold for aborted task count.

=item B<--critical-aborted>

Critical threshold for aborted task count.

=back

=cut
