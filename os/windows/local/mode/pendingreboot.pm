#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package os::windows::local::mode::pendingreboot;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::windows::pendingreboot;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'Reboot Pending : ' . $self->{result_values}->{RebootPending};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{CBServicing} = $options{new_datas}->{$self->{instance} . '_CBServicing'};
    $self->{result_values}->{RebootPending} = $options{new_datas}->{$self->{instance} . '_RebootPending'};
    $self->{result_values}->{WindowsUpdate} = $options{new_datas}->{$self->{instance} . '_WindowsUpdate'};
    $self->{result_values}->{CCMClientSDK} = $options{new_datas}->{$self->{instance} . '_CCMClientSDK'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pendingreboot', type => 0  },
    ];
    $self->{maps_counters}->{pendingreboot} = [
        { label => 'status', , threshold => 0, set => {
                key_values => [ { name => 'CBServicing' }, { name => 'RebootPending' }, { name => 'WindowsUpdate' }, 
                    { name => 'CCMClientSDK' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
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
                                  "warning-status:s"    => { name => 'warning_status', default => '%{RebootPending} =~ /true/i' },
                                  "critical-status:s"   => { name => 'critical_status', default => '' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $ps = centreon::common::powershell::windows::pendingreboot::get_powershell(
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
    
    #[CBServicing=False][WindowsUpdate=False][CCMClientSDK=][PendComputerRename=False][PendFileRename=False][PendFileRenVal=][RebootPending=False]
    $self->{pendingreboot} = {};
    while ($stdout =~ /\[(.*?)=\s*(.*?)\s*\]/mg) {
        $self->{pendingreboot}->{$1} = $2;
    }
}

1;

__END__

=head1 MODE

Check windows pending reboot.

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

=item B<--warning-status>

Set warning threshold for status (Default: '%{RebootPending} =~ /true/i').
Can used special variables like: %{RebootPending}, %{CBServicing}, %{WindowsUpdate}, %{CCMClientSDK}.

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{RebootPending}, %{CBServicing}, %{WindowsUpdate}, %{CCMClientSDK}.

=back

=cut
