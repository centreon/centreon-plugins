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

package apps::microsoft::hyperv::2012::local::mode::scvmmintegrationservice;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::scvmmintegrationservice;
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($scvmm_vm_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return 'VMAddition: ' . $self->{result_values}->{vmaddition};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{vm} = $options{new_datas}->{$self->{instance} . '_vm'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{vmaddition} = $options{new_datas}->{$self->{instance} . '_vm_addition'};
    $self->{result_values}->{operatingsystemshutdownenabled} = $options{new_datas}->{$self->{instance} . '_operating_system_shutdown_enabled'};
    $self->{result_values}->{timesynchronizationenabled} = $options{new_datas}->{$self->{instance} . '_time_synchronization_enabled'};
    $self->{result_values}->{dataexchangeenabled} = $options{new_datas}->{$self->{instance} . '_data_exchange_enabled'};
    $self->{result_values}->{heartbeatenabled} = $options{new_datas}->{$self->{instance} . '_heartbeat_enabled'};
    $self->{result_values}->{backupenabled} = $options{new_datas}->{$self->{instance} . '_backup_enabled'};
    return 0;
}

sub custom_integrationservice_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{output_label} . ': ' . $self->{result_values}->{service_status};
}

sub custom_integrationservice_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{output_label} = $options{extra_options}->{output_label};
    $self->{result_values}->{service_status} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{name_status}};
    $self->{result_values}->{vm} = $options{new_datas}->{$self->{instance} . '_vm'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All integration services are ok' }
    ];

    $self->{maps_counters}->{vm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'vm' }, { name => 'status' }, { name => 'vm_addition' }, 
                    { name => 'operating_system_shutdown_enabled' }, { name => 'time_synchronization_enabled' }, 
                    { name => 'data_exchange_enabled' }, { name => 'heartbeat_enabled' }, { name => 'backup_enabled' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'osshutdown-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'vm' }, { name => 'operating_system_shutdown_enabled' } ],
                closure_custom_calc => $self->can('custom_integrationservice_calc'),
                closure_custom_calc_extra_options => { output_label => 'operating system shutdown', name_status => 'operating_system_shutdown_enabled' },
                closure_custom_output => $self->can('custom_integrationservice_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'timesync-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'vm' }, { name => 'time_synchronization_enabled' } ],
                closure_custom_calc => $self->can('custom_integrationservice_calc'),
                closure_custom_calc_extra_options => { output_label => 'time synchronization', name_status => 'time_synchronization_enabled' },
                closure_custom_output => $self->can('custom_integrationservice_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'dataexchange-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'vm' }, { name => 'data_exchange_enabled' } ],
                closure_custom_calc => $self->can('custom_integrationservice_calc'),
                closure_custom_calc_extra_options => { output_label => 'data exchange', name_status => 'data_exchange_enabled' },
                closure_custom_output => $self->can('custom_integrationservice_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'heartbeat-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'vm' }, { name => 'heartbeat_enabled' } ],
                closure_custom_calc => $self->can('custom_integrationservice_calc'),
                closure_custom_calc_extra_options => { output_label => 'heartbeat', name_status => 'heartbeat_enabled' },
                closure_custom_output => $self->can('custom_integrationservice_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'backup-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'vm' }, { name => 'backup_enabled' } ],
                closure_custom_calc => $self->can('custom_integrationservice_calc'),
                closure_custom_calc_extra_options => { output_label => 'backup', name_status => 'backup_enabled' },
                closure_custom_output => $self->can('custom_integrationservice_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    
    return "VM '" . $options{instance_value}->{vm} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'scvmm-hostname:s'    => { name => 'scvmm_hostname' },
        'scvmm-username:s'    => { name => 'scvmm_username' },
        'scvmm-password:s'    => { name => 'scvmm_password' },
        'scvmm-port:s'        => { name => 'scvmm_port', default => 8100 },
        'timeout:s'           => { name => 'timeout', default => 50 },
        'command:s'           => { name => 'command', default => 'powershell.exe' },
        'command-path:s'      => { name => 'command_path' },
        'command-options:s'   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'               => { name => 'no_ps' },
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' },
        'filter-vm:s'         => { name => 'filter_vm' },
        'filter-description:s' => { name => 'filter_description' },
        'filter-hostgroup:s'   => { name => 'filter_hostgroup' },
        'filter-status:s'      => { name => 'filter_status' },
        'warning-status:s'     => { name => 'warning_status', default => '' },
        'critical-status:s'    => { name => 'critical_status', default => '%{vmaddition} =~ /not detected/i' },
        'warning-osshutdown-status:s'     => { name => 'warning_osshutdown_status', default => '' },
        'critical-osshutdown-status:s'    => { name => 'critical_osshutdown_status', default => '' },
        'warning-timesync-status:s'       => { name => 'warning_timesync_status', default => '' },
        'critical-timesync-status:s'      => { name => 'critical_timesync_status', default => '' },
        'warning-dataexchange-status:s'   => { name => 'warning_dataexchange_status', default => '' },
        'critical-dataexchange-status:s'  => { name => 'critical_dataexchange_status', default => '' },
        'warning-heartbeat-status:s'      => { name => 'warning_heartbeat_status', default => '' },
        'critical-heartbeat-status:s'     => { name => 'critical_heartbeat_status', default => '' },
        'warning-backup-status:s'         => { name => 'warning_backup_status', default => '' },
        'critical-backup-status:s'        => { name => 'critical_backup_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    foreach my $label (('scvmm_hostname', 'scvmm_username', 'scvmm_password', 'scvmm_port')) {
        if (!defined($self->{option_results}->{$label}) || $self->{option_results}->{$label} eq '') {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label_opt . " option.");
            $self->{output}->option_exit();
        }
    }

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'warning_osshutdown_status', 'critical_osshutdown_status',
        'warning_timesync_status', 'critical_timesync_status', 'warning_dataexchange_status', 'critical_dataexchange_status',
        'warning_heartbeat_status', 'critical_heartbeat_status', 'warning_backup_status', 'critical_backup_status'
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::scvmmintegrationservice::get_powershell(
            scvmm_hostname => $self->{option_results}->{scvmm_hostname},
            scvmm_username => $self->{option_results}->{scvmm_username},
            scvmm_password => $self->{option_results}->{scvmm_password},
            scvmm_port => $self->{option_results}->{scvmm_port}
        );
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
    #   { "name": "test1", "description": "Test Descr -  - pp -  - aa", "status": 0, "cloud": "", "host_group_path": "All Hosts\\\CORP\\\test1", "vm_addition": "6.3.9600.16384" },
    #   {
    #      "name": "test2", "description": "", "status": 0, "cloud": "", "host_group_path": "All Hosts\\\CORP\\\test2", "vm_addition": "Not Detected",
    #      "operating_system_shutdown_enabled": true,
    #      "time_synchronization_enabled": false,
    #      "data_exchange_enabled": true,
    #      "heartbeat_enabled": false,
    #      "backup_enabled": true
    #   }
    #]
    $self->{vm} = {};

    my $id = 1;
    foreach my $node (@$decoded) {
        $node->{hostgroup} = $node->{host_group_path};
        $node->{vm} = $node->{name};
        $node->{status} = $scvmm_vm_status->{ $node->{status} };

        foreach (('operating_system_shutdown_enabled', 'time_synchronization_enabled', 'data_exchange_enabled', 'heartbeat_enabled', 'backup_enabled')) {
            $node->{$_} = ($node->{$_} =~ /True|1/i ? 1 : 0) if (defined($node->{$_}));
        }

        my $filtered = 0;
        foreach (('vm', 'description', 'status', 'hostgroup')) {
            if (defined($self->{option_results}->{'filter_' . $_}) && $self->{option_results}->{'filter_' . $_} ne '' &&
                $node->{$_} !~ /$self->{option_results}->{'filter_' . $_}/i) {
                $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter.", debug => 1);
                $filtered = 1;
                last;
            }
        }

        next if ($filtered == 1);

        $self->{vm}->{$id} = {
            %$node
        };
        $id++;
    }
}

1;

__END__

=head1 MODE

Check virtual machine integration services on SCVMM.

=over 8

=item B<--scvmm-hostname>

SCVMM hostname (Required).

=item B<--scvmm-username>

SCVMM username (Required).

=item B<--scvmm-password>

SCVMM password (Required).

=item B<--scvmm-port>

SCVMM port (Default: 8100).

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

=item B<--filter-status>

Filter virtual machine status (can be a regexp).

=item B<--filter-description>

Filter by description (can be a regexp).

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--filter-hostgroup>

Filter hostgroup (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{vm}, %{vmaddition}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{vmaddition} =~ /not detected/i').
Can used special variables like: %{vm}, %{vmaddition}, %{status}

=back

=cut
