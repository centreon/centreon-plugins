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

package apps::infor::m3::monitor::api::mode::jvms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [type: %s, system: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{system},
    );
}

sub prefix_jvm_output {
    my ($self, %options) = @_;

    return "JVM '" . $options{instance_value}->{id} . "' ";
}

sub prefix_status_output {
    my ($self, %options) = @_;

    return 'JVMs statuses ';
}

sub prefix_type_output {
    my ($self, %options) = @_;

    return 'JVMs types ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'statuses', type => 0, cb_prefix_output => 'prefix_status_output' },
        { name => 'types', type => 0, cb_prefix_output => 'prefix_type_output' },
        { name => 'jvms', type => 1, cb_prefix_output => 'prefix_jvm_output', message_multiple => 'All JVMs are ok' }
    ];

    $self->{maps_counters}->{statuses} = [
        { label => 'status-normal', nlabel => 'jvms.status.normal.count', set => {
                key_values => [ { name => 'normal' }, { name => 'total' } ],
                output_template => 'normal: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'status-offline', nlabel => 'jvms.status.offline.count', set => {
                key_values => [ { name => 'offline' }, { name => 'total' } ],
                output_template => 'offline: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'status-started', nlabel => 'jvms.status.started.count', set => {
                key_values => [ { name => 'started' }, { name => 'total' } ],
                output_template => 'started: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'status-locked', nlabel => 'jvms.status.locked.count', set => {
                key_values => [ { name => 'locked' }, { name => 'total' } ],
                output_template => 'locked: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{types} = [
        { label => 'type-autojobs', nlabel => 'jvms.type.autojobs.count', set => {
                key_values => [ { name => 'autojobs' }, { name => 'total' } ],
                output_template => 'autojobs: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'type-interactivejobs', nlabel => 'jvms.type.interactivejobs.count', set => {
                key_values => [ { name => 'interactivejobs' }, { name => 'total' } ],
                output_template => 'interactivejobs: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'type-batchjobs', nlabel => 'jvms.type.batchjobs.count', set => {
                key_values => [ { name => 'batchjobs' }, { name => 'total' } ],
                output_template => 'batchjobs: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'type-mijobs', nlabel => 'jvms.type.mijobs.count', set => {
                key_values => [ { name => 'mijobs' }, { name => 'total' } ],
                output_template => 'mijobs: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'type-m3coordinator', nlabel => 'jvms.type.m3coordinator.count', set => {
                key_values => [ { name => 'm3coordinator' }, { name => 'total' } ],
                output_template => 'm3coordinator: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{jvms} = [
        {
            label => 'jvm-status',
            type => 2,
            critical_default => '%{status} =~ /locked/',
            set => {
                key_values => [
                    { name => 'id' },
                    { name => 'type' },
                    { name => 'system' },
                    { name => 'status' },
                    { name => 'cpu_usage' },
                    { name => 'heap_size' },
                    { name => 'uptime' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'jvm-cpu-usage', nlabel => 'jvm.cpu.usage.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'id' } ],
                output_template => 'CPU usage: %s %%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label => 'jvm-jobs', nlabel => 'jvm.jobs.count', set => {
                key_values => [ { name => 'job_count' }, { name => 'id' } ],
                output_template => 'Jobs: %s',
                perfdatas => [
                    { template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label => 'jvm-threads', nlabel => 'jvm.threads.count', set => {
                key_values => [ { name => 'threads' }, { name => 'id' } ],
                output_template => 'Threads: %s',
                perfdatas => [
                    { template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label => 'jvm-heap-size', nlabel => 'jvm.heap_size.bytes', set => {
                key_values => [ { name => 'heap_size' }, { name => 'id' } ],
                output_template => 'Heap Size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B',
                      label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label => 'jvm-uptime', nlabel => 'jvm.uptime.seconds', set => {
                key_values => [ { name => 'uptime' }, { name => 'uptime_human' }, { name => 'id' } ],
                output_template => 'Uptime: %s',
                output_use => 'uptime_human',
                closure_custom_perfdata => sub { return 0; },
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s' => { name => 'filter_id' },
        'filter-type:s' => { name => 'filter_type' },
        'filter-system:s' => { name => 'filter_system' }
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
        get_param => ['category=jvms'],
        force_array => ['jvms', 'jvm']
    );

    $self->{statuses} = { total => 0, normal => 0, offline => 0, started => 0, locked => 0 };
    $self->{types} = { total => 0, autojobs => 0, interactivejobs => 0, batchjobs => 0, mijobs => 0, m3coordinator => 0 };

    foreach my $entry (@{$result->{category}->{jvm}}) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne ''
            && $entry->{JVMId} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne ''
            && $entry->{type} !~ /$self->{option_results}->{filter_type}/);
        next if (defined($self->{option_results}->{filter_system}) && $self->{option_results}->{filter_system} ne ''
            && $entry->{systemConfiguration} !~ /$self->{option_results}->{filter_system}/);

        $self->{jvms}->{$entry->{JVMId}} = {
            id => $entry->{JVMId},
            type => $entry->{type},
            system => ($entry->{systemConfiguration}) ne "" ? $entry->{systemConfiguration} : "-",
            cpu_usage => $entry->{processCpuUsage},
            job_count => (defined($entry->{jobCount})) ? $entry->{jobCount} : 0,
            threads => $entry->{threads},
            heap_size => $entry->{heapSizeKB} * 1024,
            uptime => ($entry->{upTimeMS} > 0) ? $entry->{upTimeMS} / 1000 : 0,
            uptime_human => ($entry->{upTimeMS} > 0) ? centreon::plugins::misc::change_seconds(value => $entry->{upTimeMS} / 1000) : 0,
            status => $entry->{status}
        };

        $self->{statuses}->{lc($entry->{status})}++;
        $self->{statuses}->{total}++;
        $self->{types}->{lc($entry->{type})}++;
        $self->{types}->{total}++;
    }

    if (scalar(keys %{$self->{jvms}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No JVMs found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check JVMs status.

=over 8

=item B<--filter-type>

Filter by type.

=item B<--filter-system>

Filter by system.

=item B<--warning-jvm-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{id}, %{type}, %{system}.

=item B<--critical-jvm-status>

Set critical threshold for status (Default: "%{status} =~ /locked/").
Can use special variables like: %{status}, %{id}, %{type}, %{system}.

=back

=cut