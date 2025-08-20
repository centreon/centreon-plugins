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

package os::as400::connector::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub system_long_output {
    my ($self, %options) = @_;

    return 'checking system';
}

sub prefix_jobs_output {
    my ($self, %options) = @_;

    return 'jobs ';
}

sub prefix_bjobs_output {
    my ($self, %options) = @_;

    return 'batch jobs ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 3, cb_long_output => 'system_long_output', indent_long_output => '    ',
            group => [
                { name => 'cpu', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'asp1', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'jobs', type => 0, display_short => 0, cb_prefix_output => 'prefix_jobs_output', skipped_code => { -10 => 1 } },
                { name => 'bjobs', type => 0, display_short => 0, cb_prefix_output => 'prefix_bjobs_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'processing-units-usage', nlabel => 'system.processing.units.usage.percentage', set => {
                key_values => [ { name => 'units_used' } ],
                output_template => 'processing units used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{asp1} = [
        { label => 'storage-pool-space-usage', nlabel => 'system.storage.pool.space.usage.percentage', set => {
                key_values => [ { name => 'space_used' } ],
                output_template => 'storage pool space used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{jobs} = [
        { label => 'jobs-total', nlabel => 'system.jobs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'jobs-active', nlabel => 'system.jobs.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{bjobs} = [
        { label => 'batch-jobs-running', nlabel => 'system.batch_jobs.running.count', set => {
                key_values => [ { name => 'running' } ],
                output_template => 'running: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'batch-jobs-waiting-message', nlabel => 'system.batch_jobs.waiting_message.count', set => {
                key_values => [ { name => 'wfm' } ],
                output_template => 'waiting for message: %s',
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $infos = $options{custom}->request_api(command => 'getSystem');

    $self->{output}->output_add(short_msg => 'System usage is ok');

    $self->{system} = {
        global => {
            cpu  => { units_used => $infos->{result}->[0]->{percentProcessingUnitUsed} },
            asp1 => { space_used => $infos->{result}->[0]->{percentSystemASPUsed} },
            jobs => {
                total => $infos->{result}->[0]->{jobInSystem}, # Returns the total number of user jobs and system jobs that are currently in the system
                active => $infos->{result}->[0]->{activeJobInSystem}
            },
            bjobs => {
                running => $infos->{result}->[0]->{batchJobRunning},
                wfm     => $infos->{result}->[0]->{batchJobWaitingForMessage}
            }
        }
    };
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='processing-units'

=item B<--warning-batch-jobs-running>

Threshold.

=item B<--critical-batch-jobs-running>

Threshold.

=item B<--warning-batch-jobs-waiting-message>

Threshold.

=item B<--critical-batch-jobs-waiting-message>

Threshold.

=item B<--warning-jobs-active>

Threshold.

=item B<--critical-jobs-active>

Threshold.

=item B<--warning-jobs-total>

Threshold.

=item B<--critical-jobs-total>

Threshold.

=item B<--warning-processing-units-usage>

Threshold in percentage.

=item B<--critical-processing-units-usage>

Threshold in percentage.

=item B<--warning-storage-pool-space-usage>

Threshold in percentage.

=item B<--critical-storage-pool-space-usage>

Threshold in percentage.

=back

=cut
