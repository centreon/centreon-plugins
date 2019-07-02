#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::hyperv::2012::local::mode::nodeintegrationservice;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::nodeintegrationservice;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_service_status_output {
    my ($self, %options) = @_;
    my $msg = 'status : ' . $self->{result_values}->{primary_status} . '/' . $self->{result_values}->{secondary_status};

    return $msg;
}

sub custom_service_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{primary_status} = $options{new_datas}->{$self->{instance} . '_primary_status'};
    $self->{result_values}->{secondary_status} = $options{new_datas}->{$self->{instance} . '_secondary_status'};
    $self->{result_values}->{vm} = $options{new_datas}->{$self->{instance} . '_vm'};
    $self->{result_values}->{service} = $options{new_datas}->{$self->{instance} . '_service'};
    return 0;
}

sub custom_global_status_output {
    my ($self, %options) = @_;
    my $msg = 'state/version : ' . $self->{result_values}->{integration_service_state} . '/' . $self->{result_values}->{integration_service_version};

    return $msg;
}

sub custom_global_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{integration_service_state} = $options{new_datas}->{$self->{instance} . '_integration_service_state'};
    $self->{result_values}->{integration_service_version} = $options{new_datas}->{$self->{instance} . '_integration_service_version'};
    $self->{result_values}->{vm} = $options{new_datas}->{$self->{instance} . '_vm'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
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
                closure_custom_calc => $self->can('custom_global_status_calc'),
                closure_custom_output => $self->can('custom_global_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    
    $self->{maps_counters}->{service} = [
        { label => 'service-status', threshold => 0, set => {
                key_values => [ { name => 'primary_status' }, { name => 'secondary_status' }, { name => 'enabled' }, { name => 'vm' }, { name => 'service' } ],
                closure_custom_calc => $self->can('custom_service_status_calc'),
                closure_custom_output => $self->can('custom_service_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub vm_long_output {
    my ($self, %options) = @_;
    
    return "checking virtual machine '" . $options{instance_value}->{display} . "'";
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    
    return "VM '" . $options{instance_value}->{display} . "' ";
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
    
    $options{options}->add_options(arguments =>
                                {
                                  "timeout:s"           => { name => 'timeout', default => 50 },
                                  "command:s"           => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                  "no-ps"               => { name => 'no_ps' },
                                  "ps-exec-only"        => { name => 'ps_exec_only' },
                                  "filter-vm:s"         => { name => 'filter_vm' },
                                  "filter-note:s"       => { name => 'filter_note' },
                                  "filter-status:s"     => { name => 'filter_status', default => 'running' },
                                  "warning-global-status:s"     => { name => 'warning_global_status', default => '%{integration_service_state} =~ /Update required/i' },
                                  "critical-global-status:s"    => { name => 'critical_global_status', default => '' },
                                  "warning-service-status:s"    => { name => 'warning_service_status', default => '' },
                                  "critical-service-status:s"   => { name => 'critical_service_status', default => '%{primary_status} !~ /Ok/i' },
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
    
    my $ps = centreon::common::powershell::hyperv::2012::nodeintegrationservice::get_powershell(no_ps => $self->{option_results}->{no_ps});
    
    $self->{option_results}->{command_options} .= " " . $ps;
    my ($stdout) = centreon::plugins::misc::execute(output => $self->{output},
                                                    options => $self->{option_results},
                                                    command => $self->{option_results}->{command},
                                                    command_path => $self->{option_results}->{command_path},
                                                    command_options => $self->{option_results}->{command_options});
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $stdout);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }
    
    #[name= test1 ][state= Running ][IntegrationServicesState= Update required ][IntegrationServicesVersion= 3.1 ][note= ]
    #[service= Time Synchronization ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= Heartbeat ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= Key-Value Pair Exchange ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= Shutdown ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= VSS ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= Guest Service Interface ][enabled= False][primaryOperationalStatus= Ok ][secondaryOperationalStatus=  ]
    #[name= test2 ][state= Running ][IntegrationServicesState=  ][IntegrationServicesVersion= ][note= ]
    #[service= Time Synchronization ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= Heartbeat ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= Key-Value Pair Exchange ][enabled= True][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    #[service= Shutdown ][enabled= False][primaryOperationalStatus= NoContact ][secondaryOperationalStatus=  ]
    $self->{vm} = {};
    
    my $id = 1;
    while ($stdout =~ /^\[name=\s*(.*?)\s*\]\[state=\s*(.*?)\s*\]\[IntegrationServicesState=\s*(.*?)\s*\]\[IntegrationServicesVersion=\s*(.*?)\s*\]\[note=\s*(.*?)\s*\](.*?)(?=\[name=|\z)/msig) {
        my ($name, $status, $integration_service_state, $integration_service_version, $note, $content) = ($1, $2, $3, $4, $5, $6);

        if (defined($self->{option_results}->{filter_vm}) && $self->{option_results}->{filter_vm} ne '' &&
            $name !~ /$self->{option_results}->{filter_vm}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $status !~ /$self->{option_results}->{filter_status}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $status . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_note}) && $self->{option_results}->{filter_note} ne '' &&
            $note !~ /$self->{option_results}->{filter_note}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $note . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vm}->{$id} = { display => $name, vm => $name, service => {} };
        $self->{vm}->{$id}->{global} = { 
            $name => { vm => $name, integration_service_state => $integration_service_state, integration_service_version => $integration_service_version, state => $status } 
        };
        my $id2 = 1;
        while ($content =~ /^\[service=\s*(.*?)\s*\]\[enabled=\s*(.*?)\s*\]\[primaryOperationalStatus=\s*(.*?)\s*\]\[secondaryOperationalStatus=\s*(.*?)\s*\]/msig) {
            $self->{vm}->{$id}->{service}->{$id2} = { vm => $name, service => $1, enabled => $2, primary_status => $3, secondary_status => $4 };
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
