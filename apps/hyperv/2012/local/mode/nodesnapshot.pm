#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::hyperv::2012::local::mode::nodesnapshot;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::nodesnapshot;

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
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "timeout:s"           => { name => 'timeout', default => 50 },
                                  "command:s"           => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                  "no-ps"               => { name => 'no_ps' },
                                  "ps-exec-only"        => { name => 'ps_exec_only' },
                                  "filter-vm:s"         => { name => 'filter_vm' },
                                  "filter-status:s"     => { name => 'filter_status', default => 'running' },
                                });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $ps = centreon::common::powershell::hyperv::2012::nodesnapshot::get_powershell(no_ps => $self->{option_results}->{no_ps});
    
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
    
    #[name= ISC1-SV04404 ][state= Running ]
    #[checkpointCreationTime= 1475502921.28734 ]
    #[checkpointCreationTime= 1475503073.81975 ]
    $self->{vm} = {};
    
    my $id = 1;
    while ($stdout =~ /^\[name=\s*(.*?)\s*\]\[state=\s*(.*?)\s*\](.*?)(?=\[name=|\z)/msig) {
        my ($name, $status, $content) = ($1, $2, $3);
        my $chkpt = -1;
        while ($content =~ /\[checkpointCreationTime=s*(.*?)\s*\]/msig) {
            $chkpt = $1 if ($chkpt == -1 || $chkpt > $1);
        }
        next if ($chkpt == -1);

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
        
        $self->{vm}->{$id} = { display => $name, snapshot => time() - $chkpt };
        $id++;
    }
}

1;

__END__

=head1 MODE

Check virtual machine snapshots on hyper-v node.

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

=item B<--filter-status>

Filter virtual machine status (can be a regexp) (Default: 'running').

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'snapshot' (in seconds).

=item B<--critical-*>

Threshold critical.
Can be: 'snapshot' (in seconds).

=back

=cut