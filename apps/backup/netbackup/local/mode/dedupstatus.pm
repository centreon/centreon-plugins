#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::backup::netbackup::local::mode::dedupstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

my $instance_mode;

sub custom_threshold_output {
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
    my $msg = 'status : ' . $self->{result_values}->{status};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pool', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All dedup status are ok' }
    ];
    
    $self->{maps_counters}->{pool} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' } ],
                output_template => 'Use: %s %%',
                perfdatas => [
                    { label => 'used', value => 'usage_absolute', template => '%s', 
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
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
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'nbdevquery' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-listdv -U -stype PureDisk' },
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} !~ /up/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_pool_output {
    my ($self, %options) = @_;
    
    return "Disk pool name '" . $options{instance_value}->{display} . "' ";
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

    my ($stdout) = centreon::plugins::misc::execute(output => $self->{output},
                                                    options => $self->{option_results},
                                                    sudo => $self->{option_results}->{sudo},
                                                    command => $self->{option_results}->{command},
                                                    command_path => $self->{option_results}->{command_path},
                                                    command_options => $self->{option_results}->{command_options});    
    $self->{pool} = {};
    #Disk Pool Name      : NBU-MASTER-DP
    #Disk Type           : PureDisk
    #Disk Volume Name    : PureDiskVolume
    #Disk Media ID       : @aaaah
    #Total Capacity (GB) : 9777.56
    #Free Space (GB)     : 837.72
    #Use%                : 91
    #Status              : UP
    #Flag                : ReadOnWrite
    #Flag                : AdminUp
    #Flag                : InternalUp
    while ($stdout =~ /^(Disk Pool Name.*?)(?=Disk Pool Name|\z)/msig) {
        my $pool = $1;
        
        my ($display, $usage, $status);
        $display = centreon::plugins::misc::trim($1) if ($pool =~ /^Disk Pool Name\s*:\s*(.*?)\n/msi);
        $status = $1 if ($pool =~ /^Status\s*:\s*(.*?)\n/msi);
        $usage = $1 if ($pool =~ /^Use%\s*:\s*(.*?)\n/msi);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $display !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{pool}->{$display} = { display => $display, usage => $usage, status => $status };
    }
    
    if (scalar(keys %{$self->{pool}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No pool found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check deduplication status.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'nbdevquery').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-listdv -U -stype PureDisk').

=item B<--filter-name>

Filter pool name (can be a regexp).

=item B<--warning-usage>

Set warning threshold in percent.

=item B<--critical-usage>

Set critical threshold in percent.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /up/i').
Can used special variables like: %{display}, %{status}

=back

=cut
