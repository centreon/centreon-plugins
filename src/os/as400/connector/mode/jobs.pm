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

package os::as400::connector::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs-total', nlabel => 'jobs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'number of jobs: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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
        'include-active-status:s' => { name => 'include_active_status' },
        'filter-active-status:s'  => { redirect => 'include_active_status' },
        'include-name:s'          => { name => 'include_name' },
        'filter-name:s'           => { redirect => 'include_name' },
        'include-subsystem:s'     => { name => 'include_subsystem' },
        'filter-subsystem:s'      => { redirect => 'include_subsystem' },
        'display-jobs'            => { name => 'display_jobs' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{uuid} = '';
    foreach ('filter_counters', 'include_name', 'include_active_status', 'include_subsystem') {
        if (defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne '') {
            $self->{uuid} .= $self->{option_results}->{$_};
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %cmd = (command => 'listJobs', args => {});
    if ($self->{uuid} ne '') {
        $cmd{args}->{uuid} = $self->{uuid};
    }
    my $jobs = $options{custom}->request_api(%cmd);

    $self->{global} = { total => 0 };
    foreach my $entry (@{$jobs->{result}}) {
        if (defined($self->{option_results}->{include_name}) && $self->{option_results}->{include_name} ne '' &&
            $entry->{name} !~ /$self->{option_results}->{include_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $entry->{name} . "': no matching filter (name).", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{include_subsystem}) && $self->{option_results}->{include_subsystem} ne '' &&
            $entry->{subSystem} !~ /$self->{option_results}->{include_subsystem}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $entry->{name} . "': no matching filter (subsystem).", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{include_active_status}) && $self->{option_results}->{include_active_status} ne '' &&
            $entry->{activeStatus} !~ /$self->{option_results}->{include_active_status}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $entry->{name} . "': no matching filter (activeStatus).", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{display_jobs})) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    'job %s [subsystem: %s] [active status: %s]',
                    $entry->{name},
                    $entry->{subSystem},
                    $entry->{activeStatus}
                )
            );
        }

        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check active jobs.

=over 8

=item B<--include-active-status>

Filter jobs by ACTIVE_JOB_STATUS (can be a regexp).
Example: --include-active-status='MSGW' to count jobs with MSGW.

=item B<--include-name>

Filter jobs by name (can be a regexp).

=item B<--include-subsystem>

Filter jobs by subsystem (can be a regexp).

=item B<--display-jobs>

Display jobs in verbose output.

=item B<--warning-jobs-total>

Threshold.

=item B<--critical-jobs-total>

Threshold.

=back

=cut
