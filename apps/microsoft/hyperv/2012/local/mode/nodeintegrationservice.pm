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

package apps::microsoft::hyperv::2012::local::mode::nodeintegrationservice;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::nodeintegrationservice;
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($node_vm_state $node_vm_integration_service_operational_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use JSON::XS;

sub custom_service_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{primary_status} . '/' . $self->{result_values}->{secondary_status};
}

sub custom_global_status_output {
    my ($self, %options) = @_;

    return 'state/version: ' . $self->{result_values}->{integration_service_state} . '/' . $self->{result_values}->{integration_service_version};
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vm', type => 2, cb_prefix_output => 'prefix_vm_output', cb_long_output => 'vm_long_output', message_multiple => 'All integration services are ok',
          group => [ { name => 'global', cb_prefix_output => 'prefix_global_output' }, { name => 'service', cb_prefix_output => 'prefix_service_output' } ] 
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'global-status', threshold => 0, set => {
                key_values => [ { name => 'integration_service_state' }, { name => 'integration_service_version' }, { name => 'state' }, { name => 'vm' } ],
                closure_custom_output => $self->can('custom_global_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
    
    $self->{maps_counters}->{service} = [
        { label => 'service-status', threshold => 0, set => {
                key_values => [ { name => 'primary_status' }, { name => 'secondary_status' }, { name => 'enabled' }, { name => 'vm' }, { name => 'service' } ],
                closure_custom_output => $self->can('custom_service_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub vm_long_output {
    my ($self, %options) = @_;
    
    return "checking virtual machine '" . $options{instance_value}->{vm} . "'";
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    
    return "VM '" . $options{instance_value}->{vm} . "' ";
}

sub prefix_service_output {
    my ($self, %options) = @_;
    
    return "integration service '" . $options{instance_value}->{service} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "global virtual machine '" . $options{instance_value}->{vm} . "' integration service ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeout:s'           => { name => 'timeout', default => 50 },
        'command:s'           => { name => 'command', default => 'powershell.exe' },
        'command-path:s'      => { name => 'command_path' },
        'command-options:s'   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'               => { name => 'no_ps' },
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' },
        'filter-vm:s'         => { name => 'filter_vm' },
        'filter-note:s'       => { name => 'filter_note' },
        'filter-status:s'     => { name => 'filter_status', default => 'running' },
        'warning-global-status:s'   => { name => 'warning_global_status', default => '%{integration_service_state} =~ /Update required/i' },
        'critical-global-status:s'  => { name => 'critical_global_status', default => '' },
        'warning-service-status:s'  => { name => 'warning_service_status', default => '' },
        'critical-service-status:s' => { name => 'critical_service_status', default => '%{primary_status} !~ /Ok/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_service_status', 'critical_service_status', 'warning_global_status', 'critical_global_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::nodeintegrationservice::get_powershell();
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #   {
    #     "name": "test1", "state": 2, "integration_services_state": "Update required", "integration_services_version": "3.1", "note": null,
    #     "services": [
    #         { "service": "Time Synchronization", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "Key-Value Pair Exchange", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "Shutdown", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "VSS", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "Guest Service Interface", "enabled": false, "primary_operational_status": 2, "secondary_operational_status": null }
    #     ]
    #   },
    #   {
    #     "name": "test2", "state": 2, "integration_services_state": null, "integration_services_version": null, "note": null,
    #     "services": [
    #         { "service": "Time Synchronization", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "Key-Value Pair Exchange", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "Shutdown", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "VSS", "enabled": true, "primary_operational_status": 12, "secondary_operational_status": null },
    #         { "service": "Guest Service Interface", "enabled": false, "primary_operational_status": 2, "secondary_operational_status": null }
    #     ]
    #   }
    #]
    $self->{vm} = {};
    
    my $id = 1;
    foreach my $node (@$decoded) {
        if (defined($self->{option_results}->{filter_vm}) && $self->{option_results}->{filter_vm} ne '' &&
            $node->{name} !~ /$self->{option_results}->{filter_vm}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $node_vm_state->{ $node->{state} } !~ /$self->{option_results}->{filter_status}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_note}) && $self->{option_results}->{filter_note} ne '' &&
            defined($node->{note}) && $node->{note} !~ /$self->{option_results}->{filter_note}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vm}->{$id} = {
            vm => $node->{name},
            service => {}
        };
        $self->{vm}->{$id}->{global} = { 
            $node->{name} => {
                vm => $node->{name},
                integration_service_state => defined($node->{integration_services_state}) ? $node->{integration_services_state} : '-',
                integration_service_version => defined($node->{integration_services_version}) ? $node->{integration_services_version} : '-',
                state => $node_vm_state->{ $node->{state} }
            } 
        };

        my $id2 = 1;
        my $services = (ref($node->{services}) eq 'ARRAY') ? $node->{services} : [ $node->{services} ];

        foreach my $service (@$services) {
            $self->{vm}->{$id}->{service}->{$id2} = {
                vm => $node->{name},
                service => $service->{service},
                enabled => $service->{enabled} =~ /True|1/i ? 1 : 0,
                primary_status => 
                    defined($service->{primary_operational_status}) && defined($node_vm_integration_service_operational_status->{ $service->{primary_operational_status} }) ?
                        $node_vm_integration_service_operational_status->{ $service->{primary_operational_status} } : '-',
                secondary_status =>
                    defined($service->{secondary_operational_status}) && defined($node_vm_integration_service_operational_status->{ $service->{secondary_operational_status} }) ?
                        $node_vm_integration_service_operational_status->{ $service->{secondary_operational_status} } : '-'
            };
            $id2++;
        }
        
        $id++;
    }
}

1;

__END__

=head1 MODE

Check virtual machine integration services on hyper-v node.

=over 8

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--filter-note>

Filter by VM notes (can be a regexp).

=item B<--filter-status>

Filter virtual machine status (can be a regexp) (Default: 'running').

=item B<--warning-global-status>

Set warning threshold for status (Default: '%{integration_service_state} =~ /Update required/i').
Can used special variables like: %{vm}, %{integration_service_state}, 
%{integration_service_version}, %{state}

=item B<--critical-global-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{vm}, %{integration_service_state}, 
%{integration_service_version}, %{state}

=item B<--warning-service-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{vm}, %{service}, %{primary_status}, %{secondary_status}, %{enabled}

=item B<--critical-service-status>

Set critical threshold for status (Default: '%{primary_status} !~ /Ok/i').
Can used special variables like: %{vm}, %{service}, %{primary_status}, %{secondary_status}, %{enabled}

=back

=cut
