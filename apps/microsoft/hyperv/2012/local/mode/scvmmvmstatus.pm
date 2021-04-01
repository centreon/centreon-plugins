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

package apps::microsoft::hyperv::2012::local::mode::scvmmvmstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::scvmmvmstatus;
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($scvmm_vm_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;
    
    return 'status: ' . $self->{result_values}->{status};
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok' }
    ];

    $self->{maps_counters}->{vm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'vm' }, { name => 'hostgroup' }, { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'scvmm-hostname:s'     => { name => 'scvmm_hostname' },
        'scvmm-username:s'     => { name => 'scvmm_username' },
        'scvmm-password:s'     => { name => 'scvmm_password' },
        'scvmm-port:s'         => { name => 'scvmm_port', default => 8100 },
        'timeout:s'            => { name => 'timeout', default => 50 },
        'command:s'            => { name => 'command', default => 'powershell.exe' },
        'command-path:s'       => { name => 'command_path' },
        'command-options:s'    => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'                => { name => 'no_ps' },
        'ps-exec-only'         => { name => 'ps_exec_only' },
        'ps-display'           => { name => 'ps_display' },
        'filter-vm:s'          => { name => 'filter_vm' },
        'filter-description:s' => { name => 'filter_description' },
        'filter-hostgroup:s'   => { name => 'filter_hostgroup' },
        'warning-status:s'     => { name => 'warning_status', default => '' },
        'critical-status:s'    => { name => 'critical_status', default => '%{status} !~ /Running|Stopped/i' }
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
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::scvmmvmstatus::get_powershell(
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
    #   { "name": "test-server", "description": "", "status": 0, "cloud": "", "host_group_path": "All Hosts\\\CORP\\\Test\\\test-server" },
    #   { "name": "test-server2", "description": "", "status": 0, "cloud": "", "host_group_path": "All Hosts\\\CORP\\\Test\\\test-server2" }
    #]
    $self->{vm} = {};

    my $id = 1;
    foreach my $node (@$decoded) {
        if (defined($self->{option_results}->{filter_vm}) && $self->{option_results}->{filter_vm} ne '' &&
            $node->{name} !~ /$self->{option_results}->{filter_vm}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_description}) && $self->{option_results}->{filter_description} ne '' &&
            $node->{description} !~ /$self->{option_results}->{filter_description}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{node} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_hostgroup}) && $self->{option_results}->{filter_hostgroup} ne '' &&
            $node->{host_group_path} !~ /$self->{option_results}->{filter_hostgroup}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{node} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vm}->{$id} = {
            vm => $node->{name},
            status => $scvmm_vm_status->{ $node->{status} },
            hostgroup => $node->{host_group_path} 
        };
        $id++;
    }

    if (scalar(keys %{$self->{vm}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual machine found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual machine status on SCVMM.

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

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--filter-hostgroup>

Filter hostgroup (can be a regexp).

=item B<--filter-description>

Filter by description (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{vm}, %{status}, %{hostgroup}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /Running|Stopped/i').
Can used special variables like: %{vm}, %{status}, %{hostgroup}

=back

=cut
