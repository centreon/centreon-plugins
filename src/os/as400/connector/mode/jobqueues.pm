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

package os::as400::connector::mode::jobqueues;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_jobs_active_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{library}, $self->{result_values}->{name}],
        value => $self->{result_values}->{activeJob},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_jobs_scheduled_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{library}, $self->{result_values}->{name}],
        value => $self->{result_values}->{scheduledJobOnQueue},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_jobs_held_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{library}, $self->{result_values}->{name}],
        value => $self->{result_values}->{heldJobOnQueue},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub prefix_jobq_output {
    my ($self, %options) = @_;

    return sprintf(
        "Job queue '%s' [library: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{library}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Job queues ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 }  },
        { name => 'jobq', type => 1, cb_prefix_output => 'prefix_jobq_output', message_multiple => 'All job queues are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobqueues-total', nlabel => 'jobqueues.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{jobq} = [
         {
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /HELD/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'library' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'jobqueue-jobs-active', nlabel => 'jobqueue.jobs.active.count', set => {
                key_values => [ { name => 'activeJob' }, { name => 'name' }, { name => 'library' } ],
                output_template => 'active jobs: %s',
                 closure_custom_perfdata => $self->can('custom_jobs_active_perfdata')
            }
        },
        { label => 'jobqueue-jobs-scheduled', nlabel => 'jobqueue.jobs.scheduled.count', set => {
                key_values => [ { name => 'scheduledJobOnQueue' }, { name => 'name' }, { name => 'library' } ],
                output_template => 'scheduled jobs: %s',
                 closure_custom_perfdata => $self->can('custom_jobs_scheduled_perfdata')
            }
        },
        { label => 'jobqueue-jobs-held', nlabel => 'jobqueue.jobs.held.count', set => {
                key_values => [ { name => 'heldJobOnQueue' }, { name => 'name' }, { name => 'library' } ],
                output_template => 'held jobs: %s',
                 closure_custom_perfdata => $self->can('custom_jobs_held_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'jobq:s@' => { name => 'jobq' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %cmd = (command => 'getJobQueues', args => { queues => [] });
    if (defined($self->{option_results}->{jobq})) {
        foreach (@{$self->{option_results}->{jobq}}) {
            my ($library, $name) = split(/:/);
            if (defined($library) && $library ne '' && defined($name) && $name ne '') {
                push @{$cmd{args}->{queues}}, { name => $name, library => $library };
            }
        }
    }
    if (scalar(@{$cmd{args}->{queues}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --jobq option');
        $self->{output}->option_exit();
    }

    my $entries = $options{custom}->request_api(%cmd);

    $self->{global} = { total => 0 };
    $self->{jobq} = {};
    foreach my $entry (@{$entries->{result}}) {
        $self->{jobq}->{ $entry->{name} . ':' . $entry->{library} } = {
            name => $entry->{name},
            library => $entry->{library},
            status => $entry->{status},
            activeJob => $entry->{activeJob},
            scheduledJobOnQueue => $entry->{scheduledJobOnQueue},
            heldJobOnQueue => $entry->{heldJobOnQueue}
        };

        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check job queues.

=over 8

=item B<--jobq>

JOBQ selection. Example: --jobq="QGPL:QBASE" --jobq="QGPL:QPGMR"

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}, %{library}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}, %{library}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /HELD/i').
You can use the following variables: %{status}, %{name}, %{library}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'jobqueues-total', 'jobqueue-jobs-active', 
'jobqueue-jobs-scheduled', 'jobqueue-jobs-held'.

=back

=cut
