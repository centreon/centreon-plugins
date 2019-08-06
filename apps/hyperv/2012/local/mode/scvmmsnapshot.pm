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

package apps::hyperv::2012::local::mode::scvmmsnapshot;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::scvmmsnapshot;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All VM snapshots are ok' },
    ];
    $self->{maps_counters}->{vm} = [
        { label => 'snapshot', set => {
                key_values => [ { name => 'snapshot' }, { name => 'display' }],
                closure_custom_output => $self->can('custom_vm_output'),
                closure_custom_perfdata => sub { return 0; },
            }
        },
    ];
}

sub custom_vm_output {
    my ($self, %options) = @_;
    my $msg = 'checkpoint started since : ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{snapshot_absolute});

    return $msg;
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    
    return "VM '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "scvmm-hostname:s"    => { name => 'scvmm_hostname' },
                                  "scvmm-username:s"    => { name => 'scvmm_username' },
                                  "scvmm-password:s"    => { name => 'scvmm_password' },
                                  "scvmm-port:s"        => { name => 'scvmm_port', default => 8100 },
                                  "timeout:s"           => { name => 'timeout', default => 50 },
                                  "command:s"           => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                  "no-ps"               => { name => 'no_ps' },
                                  "ps-exec-only"        => { name => 'ps_exec_only' },
                                  "filter-vm:s"         => { name => 'filter_vm' },
                                  "filter-description:s"=> { name => 'filter_description' },
                                  "filter-hostgroup:s"  => { name => 'filter_hostgroup' },
                                  "filter-status:s"     => { name => 'filter_status', default => 'running' },
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
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $ps = centreon::common::powershell::hyperv::2012::scvmmsnapshot::get_powershell(scvmm_hostname => $self->{option_results}->{scvmm_hostname},
                                                                            scvmm_username => $self->{option_results}->{scvmm_username},
                                                                            scvmm_password => $self->{option_results}->{scvmm_password},
                                                                            scvmm_port => $self->{option_results}->{scvmm_port},
                                                                            no_ps => $self->{option_results}->{no_ps});
    
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
    
    #[name= test-server ][description=  ][status= Running ][cloud=  ][hostgrouppath= All Hosts\CORP\Test\test-server ]
    #[checkpointAddedTime= 1475502741.957 ]
    #[checkpointAddedTime= 1475502963.21 ]
    $self->{vm} = {};
    
    my $id = 1;
    while ($stdout =~ /^\[name=\s*(.*?)\s*\]\[description=\s*(.*?)\s*\]\[status=\s*(.*?)\s*\]\[cloud=\s*(.*?)\s*\]\[hostgrouppath=\s*(.*?)\s*\](.*?)(?=\[name=|\z)/msig) {
        my %values = (vm => $1, description => $2, status => $3, cloud => $4, hostgroup => $5);
        my $content = $6;

        my $chkpt = -1;
        while ($content =~ /\[checkpointAddedTime=\s*(.*?)\s*\]/msig) {
            $chkpt = $1 if ($chkpt == -1 || $chkpt > $1);
        }
        next if ($chkpt == -1);

        my $filtered = 0;
        $values{hostgroup} =~ s/\\/\//g;
        foreach (('vm', 'description', 'status', 'hostgroup')) {
            if (defined($self->{option_results}->{'filter_' . $_}) && $self->{option_results}->{'filter_' . $_} ne '' &&
                $values{$_} !~ /$self->{option_results}->{'filter_' . $_}/i) {
                $self->{output}->output_add(long_msg => "skipping  '" . $values{$_} . "': no matching filter.", debug => 1);
                $filtered = 1;
                last;
            }
        }
        
        $self->{vm}->{$id} = { display => $values{vm}, snapshot => time() - $chkpt }  if ($filtered == 0);
        $id++;
    }
}

1;

__END__

=head1 MODE

Check virtual machine snapshots on SCVMM.

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

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-status>

Filter virtual machine status (can be a regexp) (Default: 'running').

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--filter-description>

Filter by description (can be a regexp).

=item B<--filter-hostgroup>

Filter hostgroup (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'snapshot' (in seconds).

=item B<--critical-*>

Threshold critical.
Can be: 'snapshot' (in seconds).

=back

=cut