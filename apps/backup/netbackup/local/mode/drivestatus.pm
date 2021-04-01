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

package apps::backup::netbackup::local::mode::drivestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

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
        { name => 'drive', type => 1, cb_prefix_output => 'prefix_drive_output', message_multiple => 'All drive status are ok' }
    ];
    
    $self->{maps_counters}->{drive} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
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
                                  "hostname:s"              => { name => 'hostname' },
                                  "remote"                  => { name => 'remote' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "sudo"                    => { name => 'sudo' },
                                  "command:s"               => { name => 'command', default => 'tpconfig' },
                                  "command-path:s"          => { name => 'command_path' },
                                  "command-options:s"       => { name => 'command_options', default => '-l' },
                                  "exec-only"               => { name => 'exec_only' },
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} !~ /up/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_drive_output {
    my ($self, %options) = @_;
    
    return "Drive '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::execute(output => $self->{output},
                                                    options => $self->{option_results},
                                                    sudo => $self->{option_results}->{sudo},
                                                    command => $self->{option_results}->{command},
                                                    command_path => $self->{option_results}->{command_path},
                                                    command_options => $self->{option_results}->{command_options});
    
    if (defined($self->{option_results}->{exec_only})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $stdout);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    $self->{drive} = {};
    #robot      0    -    TLD    -       -  -          -                    {3,0,0,1}
    #  drive    -    0 hcart2    2      UP  -          IBM.ULT3580-HH5.000  {3,0,1,0}
    #  drive    -    2 hcart2    1      UP  -          IBM.ULT3580-HH5.002  {3,0,0,0}
    while ($stdout =~ /^robot\s+(\d+)(.*?)(?=robot\s+\d+|\z)/msig) {
        my ($robot_num, $drives) = ($1, $2);
        while ($drives =~ /drive\s+\S+\s+(\d+)\s+\S+\s+\S+\s+(\S+)/msig) {
            my $name = $robot_num . '.' . $1;
            
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $name !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
                next;
            }
            $self->{drive}->{$name} = { display => $name, status => $2 };
        }
    }
    
    if (scalar(keys %{$self->{drive}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No drives found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check drive status.

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

Command to get information (Default: 'tpconfig').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-l').

=item B<--exec-only>

Print command output

=item B<--filter-name>

Filter drive name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /up/i').
Can used special variables like: %{display}, %{status}

=back

=cut
