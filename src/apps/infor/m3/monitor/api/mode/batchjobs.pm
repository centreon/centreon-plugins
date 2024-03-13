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

package apps::infor::m3::monitor::api::mode::batchjobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [name: %s, owner: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{name},
        $self->{result_values}->{owner}
    );
}

sub prefix_batchjobs_output {
    my ($self, %options) = @_;

    return "Batch job '" . $options{instance_value}->{thread_id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'batchjobs', type => 1, cb_prefix_output => 'prefix_batchjobs_output', message_multiple => 'All batch jobs are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs', nlabel => 'jobs.batch.count', set => {
                key_values => [ { name => 'jobs' } ],
                output_template => 'Batch jobs : %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{batchjobs} = [
        {
            label => 'status',
            type => 2,
            critical_default => '',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'owner' }, { name => 'thread_id' }, { name => 'jvm_id' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'batchjob-cpu-usage', nlabel => 'batchjob.cpu.usage.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'thread_id' } ],
                output_template => 'CPU usage: %s %%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'thread_id' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'filter-jvm-id:s' => { name => 'filter_jvm_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'GET',
        url_path => '/monitor',
        get_param => ['category=batchjobs'],
        force_array => ['batchjobs', 'job']
    );

    $self->{global}->{jobs} = 0;

    foreach my $entry (@{$result->{category}->{job}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_jvm_id}) && $self->{option_results}->{filter_jvm_id} ne ''
            && $entry->{JVMId} !~ /$self->{option_results}->{filter_jvm_id}/);
        $self->{batchjobs}->{$entry->{threadId}} = {
            jvm_id => $entry->{JVMId},
            thread_id => $entry->{threadId},
            name => $entry->{name},
            owner => $entry->{owner},
            status => $entry->{status},
            cpu_usage => $entry->{cpuUsage}
        };
        $self->{global}->{jobs}++;
    }
}

1;

__END__

=head1 MODE

Check batch jobs status.

=over 8

=item B<--filter-name>

Filter by name.

=item B<--filter-jvm-id>

Filter by JVM ID.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{owner}, %{jvm_id}, %{name}.

=item B<--critical-status>

Set critical threshold for status (Default: "").
Can use special variables like: %{status}, %{owner}, %{jvm_id}, %{name}.

=back

=cut