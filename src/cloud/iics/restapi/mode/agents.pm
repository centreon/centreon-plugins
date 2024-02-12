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

package cloud::iics::restapi::mode::agents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_agent_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'readyToRun: %s [active: %s]',
        $self->{result_values}->{readyToRun},
        $self->{result_values}->{active}
    );
}

sub custom_engine_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [desired: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{desiredStatus}
    );
}

sub agent_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking agent '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_agent_output {
    my ($self, %options) = @_;

    return sprintf(
        "agent '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of agents ';
}

sub prefix_engine_output {
    my ($self, %options) = @_;

    return sprintf(
        "engine application '%s' ",
        $options{instance_value}->{appDisplayName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'agents', type => 3, cb_prefix_output => 'prefix_agent_output', cb_long_output => 'agent_long_output', indent_long_output => '    ', message_multiple => 'All agents are ok',
            group => [
                { name => 'agent_status', type => 0 },
                { name => 'engines', type => 1, cb_prefix_output => 'prefix_engine_output', message_multiple => 'engines are ok', display_long => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'agents-detected', display_ok => 0, nlabel => 'agents.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{agent_status} = [
        {
            label => 'agent-status',
            type => 2,
            critical_default => '%{active} eq "yes" and %{readyToRun} eq "no"',
            set => {
                key_values => [
                    { name => 'id' }, { name => 'name' },
                    { name => 'readyToRun' }, { name => 'active' }
                ],
                closure_custom_output => $self->can('custom_agent_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{engines} = [
        {
            label => 'engine-status',
            type => 2,
            set => {
                key_values => [
                    { name => 'status' }, { name => 'desiredStatus' },
                    { name => 'agentName'}, { name => 'appDisplayName' }
                ],
                closure_custom_output => $self->can('custom_engine_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-agent-id:s'     => { name => 'filter_agent_id' },
        'filter-agent-name:s'   => { name => 'filter_agent_name' },
        'filter-agent-active:s' => { name => 'filter_agent_active' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $agents = $options{custom}->request_api(endpoint => '/api/v2/agent');
    my $agentDetails = $options{custom}->request_api(endpoint => '/api/v2/agent/details/');

    $self->{global} = { detected => 0 };
    $self->{agents} = {};

    foreach my $agent (@$agents) {
        $agent->{active} = ($agent->{active} =~ /true|1/i ? 'yes' : 'no');

        next if (defined($self->{option_results}->{filter_agent_active}) && $self->{option_results}->{filter_agent_active} ne '' &&
            $agent->{active} !~ /$self->{option_results}->{filter_agent_active}/);
        next if (defined($self->{option_results}->{filter_agent_id}) && $self->{option_results}->{filter_agent_id} ne '' &&
            $agent->{id} !~ /$self->{option_results}->{filter_agent_id}/);
        next if (defined($self->{option_results}->{filter_agent_name}) && $self->{option_results}->{filter_agent_name} ne '' &&
            $agent->{name} !~ /$self->{option_results}->{filter_agent_name}/);

        $self->{global}->{detected}++;

        $self->{agents}->{ $agent->{id} } = {
            name => $agent->{name},
            agent_status => {
                id => $agent->{id},
                name => $agent->{name},
                active => $agent->{active},
                readyToRun => $agent->{readyToRun} =~ /true|1/i ? 'yes' : 'no'
            },
            engines => {}
        };

        foreach my $agentDetail (@$agentDetails) {
            next if ($agentDetail->{id} ne $agent->{id});

            foreach my $engine (@{$agentDetail->{agentEngines}}) {
                $self->{agents}->{ $agent->{id} }->{engines}->{ $engine->{agentEngineStatus}->{appname} } = {
                    agentName => $agent->{name},
                    appDisplayName => $engine->{agentEngineStatus}->{appDisplayName},
                    desiredStatus => lc($engine->{agentEngineStatus}->{desiredStatus}),
                    status => lc($engine->{agentEngineStatus}->{status})
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check agents.

=over 8

=item B<--filter-agent-id>

Filter agents by id.

=item B<--filter-agent-name>

Filter agents by name.

=item B<--filter-agent-active>

Filter agents if active or not.

=item B<--unknown-agent-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{active}, %{readyToRun}, %{id}, %{name}

=item B<--warning-agent-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{active}, %{readyToRun}, %{id}, %{name}

=item B<--critical-agent-status>

Define the conditions to match for the status to be CRITICAL (default: '%{active} eq "yes" and %{readyToRun} eq "no"').
You can use the following variables: %{active}, %{readyToRun}, %{id}, %{name}

=item B<--unknown-engine-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{agentName}, %{appDisplayName}, %{status}, %{desiredStatus}

=item B<--warning-engine-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{agentName}, %{appDisplayName}, %{status}, %{desiredStatus}

=item B<--critical-engine-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{agentName}, %{appDisplayName}, %{status}, %{desiredStatus}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'agents-detected'.

=back

=cut
