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

package apps::scalecomputing::restapi::mode::vdomainstatus;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub custom_status_output {
    my ($self, %options) = @_;

    my $output = sprintf(
        "Virtual domain %s - %s, tag: %s, state: %s, last task (%s): %s - %s",
        $self->{result_values}->{display},
        $self->{result_values}->{description},
        $self->{result_values}->{tags},
        $self->{result_values}->{state},
        $self->{result_values}->{task_description},
        $self->{result_values}->{task_state},
        $self->{result_values}->{desired_disposition},
    );

    if (defined($self->{result_values}->{task_message}) && length($self->{result_values}->{task_message})) {
        $output .= " - message: $self->{result_values}->{task_message}";
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'vdomains',
            type             => 1,
            message_multiple => 'All virtual domains are ok',
            skipped_code     => { -10 => 1, -11 => 1 }
        }
    ];

    $self->{maps_counters}->{vdomains} = [
        {
            label            => 'status',
            type             => 2,
            warning_default  =>
                '%{state} =~ /PAUSED|SHUTDOWN/ || %{ui_state} =~ /BLOCKED|PAUSED|SHUTDOWN/',
            critical_default =>
                '%{state} =~ /BLOCKED|CRASHED|SHUTOFF/ || %{ui_state} =~ /CRASHED|SHUTOFF/ || %{state} ne %{desired_disposition} || %{task_state} eq "ERROR"',
            unknown_default  => '%{task_state} eq "UNINITIALIZED"',
            set              =>
                {
                    key_values                     => [
                        { name => 'display' },
                        { name => 'description' },
                        { name => 'tags' },
                        { name => 'state' },
                        { name => 'task_progress_percent' },
                        { name => 'task_state' },
                        { name => 'task_description' },
                        { name => 'task_message' },
                        { name => 'desired_disposition' },
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'uuid:s'             => { name => 'uuid' },
            'filter-node-uuid:s' => { name => 'filter_node_uuid' },
            'use-name'           => { name => 'use_name' }
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $virtual_domains = $options{custom}->list_virtual_domains();
    foreach my $virtual_domain (@{$virtual_domains}) {
        if (defined($self->{option_results}->{uuid}) && $self->{option_results}->{uuid} ne '' &&
            $virtual_domain->{uuid} !~ /$self->{option_results}->{uuid}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $virtual_domain->{uuid} . "' . ", debug => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_node_uuid}) && $self->{option_results}->{filter_node_uuid} ne '' &&
            $virtual_domain->{nodeUUID} !~ /$self->{option_results}->{filter_node_uuid}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $virtual_domain->{nodeUUID} . "'.", debug => 1
            );
            next;
        }

        push @{$self->{filtered_domains}}, $virtual_domain;
    }

    foreach my $virtual_domain (@{$self->{filtered_domains}}) {
        my $node_task = $virtual_domain->{latestTaskTag};
        # add the instance
        $self->{vdomains}->{$virtual_domain->{uuid}} = {
            display               => defined($self->{option_results}->{use_name}) ?
                $virtual_domain->{name} : $virtual_domain->{uuid},
            uuid                  => $virtual_domain->{uuid},
            node_uuid             => $virtual_domain->{nodeUUID},
            name                  => $virtual_domain->{name},
            description           => $virtual_domain->{description},
            operating_system      => $virtual_domain->{operatingSystem},
            state                 => $virtual_domain->{state},
            desired_disposition   => $virtual_domain->{desiredDisposition},
            tags                  => $virtual_domain->{tags},
            ui_state              => $virtual_domain->{uiState},
            guest_agent_state     => $virtual_domain->{guestAgentState},
            task_progress_percent => defined($node_task) ? $node_task->{progressPercent} : "no task",
            task_state            => defined($node_task) ? $node_task->{state} : "UNINITIALIZED",
            task_description      => defined($node_task) ? $node_task->{formattedDescription} : "no task",
            task_message          => defined($node_task) ? $node_task->{formattedMessage} : "no task",
        };
    }
}

1;

__END__

=head1 MODE

Monitor the status of a virtual domain

=over 8

=item B<--use-name>

Use cluster name for perfdata and display.

=item B<--uuid>

Gets virtual domains by uuid.

=item B<--filter-node-uuid>

Filters all virtual domains by node uuid.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{task_state} eq "UNINITIALIZED"').
You can use the following variables: %{state}, %{desired_disposition}, %{guest_agent_state},  %{task_progress_percent}, %{task_description}, %{task_message}, %{ui_state}

%{state} can be 'RUNNING', 'BLOCKED', 'PAUSED', 'SHUTDOWN', 'SHUTOFF', 'CRASHED'.

%{ui_state} can be 'RUNNING', 'BLOCKED', 'PAUSED', 'SHUTDOWN', 'SHUTOFF', 'CRASHED', 'STARTING', 'PAUSING', 'STOPPING', 'MIGRATING'.

%{task_state} can be 'UNINITIALIZED', 'QUEUED', 'RUNNING', 'COMPLETE', 'ERROR'.

%{guest_agent_state} can be 'UNKNOWN', 'UNAVAILABLE', 'AVAILABLE'.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /PAUSED|SHUTDOWN/ || %{ui_state} =~ /BLOCKED|PAUSED|SHUTDOWN/').
You can use the following variables: %{state}, %{desired_disposition}, %{guest_agent_state},  %{task_progress_percent}, %{task_description}, %{task_message}, %{ui_state}

%{state} can be 'RUNNING', 'BLOCKED', 'PAUSED', 'SHUTDOWN', 'SHUTOFF', 'CRASHED'.

%{ui_state} can be 'RUNNING', 'BLOCKED', 'PAUSED', 'SHUTDOWN', 'SHUTOFF', 'CRASHED', 'STARTING', 'PAUSING', 'STOPPING', 'MIGRATING'.

%{task_state} can be 'UNINITIALIZED', 'QUEUED', 'RUNNING', 'COMPLETE', 'ERROR'.

%{guest_agent_state} can be 'UNKNOWN', 'UNAVAILABLE', 'AVAILABLE'.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /BLOCKED|CRASHED|SHUTOFF/ || %{ui_state} =~ /CRASHED|SHUTOFF/ || %{state} ne %{desired_disposition} || %{task_state} eq "ERROR"').
You can use the following variables: %{state}, %{desired_disposition}, %{guest_agent_state},  %{task_progress_percent}, %{task_description}, %{task_message}, %{ui_state}

%{state} can be 'RUNNING', 'BLOCKED', 'PAUSED', 'SHUTDOWN', 'SHUTOFF', 'CRASHED'.

%{ui_state} can be 'RUNNING', 'BLOCKED', 'PAUSED', 'SHUTDOWN', 'SHUTOFF', 'CRASHED', 'STARTING', 'PAUSING', 'STOPPING', 'MIGRATING'.

%{task_state} can be 'UNINITIALIZED', 'QUEUED', 'RUNNING', 'COMPLETE', 'ERROR'.

%{guest_agent_state} can be 'UNKNOWN', 'UNAVAILABLE', 'AVAILABLE'.

=back

=cut
