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

package apps::microsoft::hyperv::2012::local::mode::nodeintegrationservice;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::nodeintegrationservice;
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($node_vm_state $node_vm_integration_service_operational_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use JSON::XS;

sub custom_service_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{primary_status} . '/' . $self->{result_values}->{secondary_status};
}

sub custom_global_status_output {
    my ($self, %options) = @_;

    return 'state/version: ' . $self->{result_values}->{integration_service_state} . '/' . $self->{result_values}->{integration_service_version};
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vm', type => 2, cb_prefix_output => 'prefix_vm_output', cb_long_output => 'vm_long_output', message_multiple => 'All integration services are ok',
          group => [ { name => 'global', cb_prefix_output => 'prefix_global_output' }, { name => 'service', cb_prefix_output => 'prefix_service_output' } ] 
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'global-status', type => 2, warning_default => '%{integration_service_state} =~ /Update required/i', set => {
                key_values => [ { name => 'integration_service_state' }, { name => 'integration_service_version' }, { name => 'state' }, { name => 'vm' } ],
                closure_custom_output => $self->can('custom_global_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    $self->{maps_counters}->{service} = [
        { label => 'service-status', type => 2, critical_default => '%{primary_status} !~ /Ok/i', set => {
                key_values => [ { name => 'primary_status' }, { name => 'secondary_status' }, { name => 'enabled' }, { name => 'vm' }, { name => 'service' } ],
                closure_custom_output => $self->can('custom_service_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'filter-vm:s'       => { name => 'filter_vm' },
        'filter-note:s'     => { name => 'filter_note' },
        'filter-status:s'   => { name => 'filter_status', default => 'running' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    $self->{option_results}->{command} = 'powershell.exe'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');
    $self->{option_results}->{command_options} = '-InputFormat none -NoLogo -EncodedCommand'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');
}

sub determine_operational_status {
    my ($operational_status) = @_;

    if ( defined($operational_status) ) {
        if ( defined($node_vm_integration_service_operational_status->{ $operational_status}) ) {
            return $node_vm_integration_service_operational_status->{ $operational_status };
        } else {
            return $operational_status;
        }
    } else {
        return '-';
    }
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
                primary_status => determine_operational_status($service->{primary_operational_status}),
                secondary_status => determine_operational_status($service->{secondary_operational_status})
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

Set timeout time for command execution (default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (default: none).

=item B<--command-options>

Command options (default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--filter-note>

Filter by VM notes (can be a regexp).

=item B<--filter-status>

Filter virtual machine status (can be a regexp) (default: 'running').

=item B<--warning-global-status>

Define the conditions to match for the status to be WARNING (default: '%{integration_service_state} =~ /Update required/i').
You can use the following variables: %{vm}, %{integration_service_state}, 
%{integration_service_version}, %{state}

=item B<--critical-global-status>

Define the conditions to match for the status to be CRITICAL (default: '').
You can use the following variables: %{vm}, %{integration_service_state}, 
%{integration_service_version}, %{state}

=item B<--warning-service-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{vm}, %{service}, %{primary_status}, %{secondary_status}, %{enabled}

=item B<--critical-service-status>

Define the conditions to match for the status to be CRITICAL (default: '%{primary_status} !~ /Ok/i').
You can use the following variables: %{vm}, %{service}, %{primary_status}, %{secondary_status}, %{enabled}

=back

=cut
