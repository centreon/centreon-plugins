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

package cloud::azure::compute::virtualmachine::mode::vmsstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf('state: %s', $self->{result_values}->{state});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total vitual machines ";
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    
    return "Virtual machine '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'vms', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-running', set => {
                key_values => [ { name => 'running' }  ],
                output_template => "running : %s",
                perfdatas => [
                    { label => 'total_running', value => 'running', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-stopped', set => {
                key_values => [ { name => 'stopped' }  ],
                output_template => "stopped : %s",
                perfdatas => [
                    { label => 'total_stopped', value => 'stopped', template => '%d', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{vms} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        running => 0, stopped => 0,
    };
    $self->{vms} = {};
    my $vms = $options{custom}->azure_list_vms(resource_group => $self->{option_results}->{resource_group}, show_details => 1);
    foreach my $vm (@{$vms}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $vm->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $vm->{name} . "': no matching filter.", debug => 1);
            next;
        }
            
        $self->{vms}->{$vm->{id}} = { 
            display => $vm->{name}, 
            state => $vm->{powerState},
        };

        foreach my $state (keys %{$self->{global}}) {
            $self->{global}->{$state}++ if ($vm->{powerState} =~ /$state/);
        }
    }
    
    if (scalar(keys %{$self->{vms}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual machines found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual machines status (Only with az CLI).

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin --custommode=azcli --mode=vms-state
--filter-name='.*' --filter-counters='^total-running$' --critical-total-running='10' --verbose

=over 8

=item B<--resource-group>

Set resource group (Optional).

=item B<--filter-name>

Filter resource name (Can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-running$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{state}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-running', 'total-stopped'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-running', 'total-stopped'.

=back

=cut
