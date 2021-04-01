#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package cloud::docker::restapi::mode::servicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [node: %s (%s)] [container: %s] [desired state: %s] [message: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{node_name},
        $self->{result_values}->{node_id},
        $self->{result_values}->{container_id},
        $self->{result_values}->{desired_state},
        $self->{result_values}->{state_message}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        {
            name => 'services', type => 2, message_multiple => 'All services running well', 
            format_output => '%s services not in desired stated',
            display_counter_problem => {  nlabel => 'services.tasks.problems.count', min => 0 },
            group => [ { name => 'service', cb_prefix_output => 'prefix_service_output', skipped_code => { -11 => 1 } } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tasks-total', nlabel => 'services.tasks.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total tasks of services: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{service} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ 
                    { name => 'service_name' }, { name => 'task_id' },
                    { name => 'node_name' }, { name => 'node_id' },
                    { name => 'desired_state' }, { name => 'state_message' },
                    { name => 'service_id' }, { name => 'container_id' },
                    { name => 'state' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_service_output {
    my ($self, %options) = @_;
    
    return "service '" . $options{instance_value}->{service_name} . "' task '" . $options{instance_value}->{task_id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'filter-service-name:s' => { name => 'filter_service_name' },
        'unknown-status:s'      => { name => 'unknown_status', default => '' },
        'warning-status:s'      => { name => 'warning_status', default => '' },
        'critical-status:s'     => { name => 'critical_status', default => '%{desired_state} ne %{state} and %{state} !~ /complete|preparing|assigned/' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->api_list_services();

    $self->{global} = { total => 0 };
    $self->{services}->{global} = { service => {} };

    foreach my $service_id (keys %$results) {
        foreach my $task_id (keys %{$results->{$service_id}}) {
            if (defined($self->{option_results}->{filter_service_name}) && $self->{option_results}->{filter_service_name} ne '' &&
                $results->{$service_id}->{$task_id}->{service_name} !~ /$self->{option_results}->{filter_service_name}/) {
                $self->{output}->output_add(long_msg => "skipping service '" . $results->{$service_id}->{$task_id}->{service_name} . "': no matching filter type.", debug => 1);
                next;
            }

            $self->{services}->{global}->{service}->{ $task_id } = {
                service_id => $service_id,
                task_id => $task_id,
                %{$results->{$service_id}->{$task_id}}
            };

            $self->{global}->{total}++;
        }
    }
}

1;

__END__

=head1 MODE

Check service status.

=over 8

=item B<--filter-service-name>

Filter service by service name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{service_id}, %{task_id}, %{service_name}, %{node_name}, %{node_id}, %{desired_state}, %{state_message}, %{container_id}.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{service_id}, %{task_id}, %{service_name}, %{node_name}, %{node_id}, %{desired_state}, %{state_message}, %{container_id}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{desired_state} ne %{state} and %{state} !~ /complete|preparing|assigned/').
Can used special variables like: %{service_id}, %{task_id}, %{service_name}, %{node_name}, %{node_id}, %{desired_state}, %{state_message}, %{container_id}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tasks-total'.

=back

=cut
