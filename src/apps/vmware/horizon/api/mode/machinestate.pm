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

package apps::vmware::horizon::api::mode::machinestate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my @states = (
    'AVAILABLE',
    'CONNECTED',
    'DISCONNECTED',
    'PROVISIONING',
    'WAIT_FOR_AGENT',
    'CUSTOMIZING',
    'DELETING',
    'MAINTENANCE',
    'PROVISIONED',
    'UNASSIGNED_USER_CONNECTED',
    'UNASSIGNED_USER_DISCONNECTED',
    'IN_PROGRESS',
    'DISABLED',
    'DISABLE_IN_PROGRESS',
    'VALIDATING',
    'ALREADY_USED',
    'PROVISIONING_ERROR',
    'UNKNOWN',
    'AGENT_ERR_STARTUP_IN_PROGRESS',
    'AGENT_ERR_DISABLED',
    'AGENT_ERR_INVALID_IP',
    'AGENT_ERR_NEED_REBOOT',
    'AGENT_ERR_PROTOCOL_FAILURE',
    'AGENT_ERR_DOMAIN_FAILURE',
    'AGENT_CONFIG_ERROR',
    'AGENT_UNREACHABLE',
    'ERROR'
);

sub prefix_machine_output {
    my ($self, %options) = @_;

    return "Machine '" . $options{instance_value}->{name} . "' ";
}


sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "state is '%s'",
            $self->{result_values}->{state}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Machines ';
}
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
            cb_prefix_output => 'prefix_global_output'
        },
        {
            name => 'machines',
            type => 1,
            cb_prefix_output => 'prefix_machine_output',
            message_multiple => 'All machines are ok'
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'total',
            nlabel => 'machines.total.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'total' }
                ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    foreach (@states) {
        my $label = $_;
        $label =~ s/_/-/g;
        my $output = $_;
        $output =~ s/_/ /g;
        push @{$self->{maps_counters}->{global}}, {
            label => lc($label),
            nlabel => 'machines.' . lc($_) . '.count',
            set => {
                key_values => [
                    { name => $_ }
                ],
                output_template => lc($output) . ': %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    }

    $self->{maps_counters}->{machines} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{state} !~ /available|connected|disconnected/i',
            set => {
                key_values => [
                    { name => 'state' },
                    { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'filter-name:s'            => { name => 'filter_name' },
        'filter-access-group-id:s' => { name => 'filter_access_group_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global}->{total} = 0;
    foreach (@states) {
        $self->{global}->{$_} = 0;
    };
    $self->{machines} = {};

    my $result = $options{custom}->get_inventory_machines;

    foreach my $entry (@{$result}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_access_group_id}) && $self->{option_results}->{filter_access_group_id} ne ''
            && $entry->{access_group_id} !~ /$self->{option_results}->{filter_access_group_id}/);
        
        $self->{machines}->{$entry->{id}} = {
            %{$entry}
        };

        $self->{global}->{$entry->{state}}++;
        $self->{global}->{total}++;
    }

    if (scalar(keys %{$self->{machines}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No machines found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check machine state.

=over 8

=item B<--filter-name>

Filter machines by name.

=item B<--filter-access-group-id>

Filter machines by access group id.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{state}, %{name}.

=item B<--critical-status>

Set critical threshold for status (Default: "%{state} !~ /available|connected|disconnected/i").
Can use special variables like: %{state}, %{name}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'disconnected', 'available', 'connected', 'provisioning',
'wait-for-agent', 'customizing', 'deleting', 'maintenance', 'provisioned',
'unassigned-user-connected', 'unassigned-user-disconnected', 'in-progress',
'disabled', 'disable-in-progress', 'validating', 'already-used',
'provisioning-error', 'unknown', 'agent-err-startup-in-progress',
'agent-err-disabled', 'agent-err-invalid-ip', 'agent-err-need-reboot',
'agent-err-protocol-failure', 'agent-err-domain-failure', 'agent-config-error',
'agent-unreachable', 'error'.

=back

=cut
