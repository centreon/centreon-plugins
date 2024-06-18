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

package apps::infor::ion::grid::mode::node;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_heap_output {
    my ($self, %options) = @_;

    return sprintf(
        'Heap usage: %s%s/%s%s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{heap_used}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{heap_max}),
        $self->{result_values}->{heap_percent}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "state is '%s'",
        $self->{result_values}->{state}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "Node '%s' with PID '%s' from application '%s' on host '%s' ",
        $options{instance_value}->{name},
        $options{instance_value}->{pid},
        $options{instance_value}->{application_name},
        $options{instance_value}->{host_name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name             => 'nodes',
          type             => 1,
          cb_prefix_output => 'prefix_node_output',
          message_multiple => 'All nodes are ok' },
    ];

    $self->{maps_counters}->{nodes} = [
        {
            label           => 'status',
            type            => 2,
            warning_default => '%{state} !~ /online/',
            set             => {
                key_values                     => [
                    { name => 'state' }, { name => 'name' }, { name => 'host_name' },
                    { name => 'application_name' }, { name => 'type' }, { name => 'pid' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'log-error', nlabel => 'node.log.error.count', set => {
            key_values      => [{ name => 'logger_error' }, { name => 'pid' }],
            output_template => 'Log error: %d',
            perfdatas       => [
                { template             => '%d', min => 0,
                  label_extra_instance => 1, instance_use => 'pid' }
            ]
        }
        },
        { label => 'log-warning', nlabel => 'node.log.warning.count', set => {
            key_values      => [{ name => 'logger_warning' }, { name => 'pid' }],
            output_template => 'Log warning: %d',
            perfdatas       => [
                { template             => '%d', min => 0,
                  label_extra_instance => 1, instance_use => 'pid' }
            ]
        }
        },
        { label => 'uptime', nlabel => 'node.uptime.seconds', set => {
            key_values              => [{ name => 'uptime' }, { name => 'uptime_human' }],
            output_template         => 'Uptime: %s',
            output_use              => 'uptime_human',
            closure_custom_perfdata => sub { return 0; },
        }
        },
        { label => 'cpu-usage', nlabel => 'node.cpu.usage.percentage', set => {
            key_values      => [{ name => 'cpu_percent' }, { name => 'pid' }],
            output_template => 'CPU usage: %.2f%%',
            perfdatas       => [
                { template             => '%.2f', min => 0, max => 100, unit => '%',
                  label_extra_instance => 1, instance_use => 'pid' }
            ]
        }
        },
        { label => 'heap-usage', nlabel => 'node.heap.usage.percentage', set => {
            key_values            => [{ name => 'heap_percent' }, { name => 'heap_used' },
                                      { name => 'heap_max' }, { name => 'pid' }],
            closure_custom_output => $self->can('custom_heap_output'),
            perfdatas             => [
                { template             => '%.2f', min => 0, max => 100, unit => '%',
                  label_extra_instance => 1, instance_use => 'pid' }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-type:s'             => { name => 'filter_type' },
        'filter-name:s'             => { name => 'filter_name' },
        'filter-application-name:s' => { name => 'filter_application_name' },
        'filter-host-name:s'        => { name => 'filter_host_name' }
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
        method   => 'GET',
        url_path => '/grid/rest/nodes'
    );

    foreach my $entry (@{$result}) {
        next if (defined($self->{option_results}->{filter_type})
                 && $self->{option_results}->{filter_type} ne ''
                 && $entry->{entityType} !~ /$self->{option_results}->{filter_type}/i);
        next if (defined($self->{option_results}->{filter_name})
                 && $self->{option_results}->{filter_name} ne ''
                 && $entry->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_host_name})
                 && $self->{option_results}->{filter_host_name} ne ''
                 && $entry->{hostName} !~ /$self->{option_results}->{filter_host_name}/);
        next if (defined($self->{option_results}->{filter_application_name})
                 && $self->{option_results}->{filter_application_name} ne ''
                 && $entry->{applicationName} !~ /$self->{option_results}->{filter_application_name}/);
        $self->{nodes}->{$entry->{jvmId}} = {
            type             => ucfirst(lc($entry->{entityType})),
            name             => $entry->{name},
            application_name => $entry->{applicationName},
            host_name        => $entry->{hostName},
            uptime           => ($entry->{upTime} > 0) ? $entry->{upTime} / 1000 : 0,
            uptime_human     => ($entry->{upTime} > 0) ? centreon::plugins::misc::change_seconds(value => $entry->{upTime} / 1000) : 0,
            logger_error     => $entry->{loggerErrorCount},
            logger_warning   => $entry->{loggerWarningCount},
            heap_used        => $entry->{memoryUsed},
            heap_max         => $entry->{memoryMax},
            heap_percent     => $entry->{memoryUsed} / $entry->{memoryMax} * 100,
            cpu_percent      => $entry->{cpuPercent},
            state            => ($entry->{online}) ? "online" : "offline"
        };
        $self->{nodes}->{$entry->{jvmId}}->{pid} = $1 if ($entry->{jvmId} =~ /-(\d+)$/); # 10.1.2.3:50156-5152
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor the status and the statistics of the nodes.

=over 8

=item B<--filter-type>

Define which nodes should be monitored based on the their type. This option will be treated as a regular expression.

=item B<--filter-name>

Define which nodes should be monitored based on the their name. This option will be treated as a regular expression.

=item B<--filter-application-name>

Define which applications should be monitored based on the their name. This option will be treated as a regular expression.

=item B<--filter-host-name>

Define which hosts should be monitored based on the their name. This option will be treated as a regular expression.

=item B<--warning-status>

Define the conditions to match to return a warning status (default: "%{state} !~ /online/").
The condition can be written using the following macros: %{state}, %{name}, %{host_name},
%{application_name}, %{type}.

=item B<--critical-status>

Define the conditions to match to return a critical status.
The condition can be written using the following macros: %{state}, %{name}, %{host_name},
%{application_name}, %{type}.

=item B<--warning-*> B<--critical-*>

Thresholds for 'log-error', 'log-warning', 'uptime' (s), 'cpu-usage', 'heap-usage' (%).

=back

=cut