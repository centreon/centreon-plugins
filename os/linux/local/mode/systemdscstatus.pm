#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package os::linux::local::mode::systemdscstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'status : %s/%s/%s [boot: %s]',
        $self->{result_values}->{load},
        $self->{result_values}->{active},
        $self->{result_values}->{sub},
        $self->{result_values}->{boot}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sc', type => 1, cb_prefix_output => 'prefix_sc_output', message_multiple => 'All services are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-running', nlabel => 'systemd.services.running.count', set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'Total Running: %s',
                perfdatas => [
                    { label => 'total_running', value => 'running', template => '%s', 
                      min => 0, max => 'total' },
                ],
            }
        },
        { label => 'total-failed', nlabel => 'systemd.services.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'Total Failed: %s',
                perfdatas => [
                    { label => 'total_failed', value => 'failed', template => '%s', 
                      min => 0, max => 'total' },
                ],
            }
        },
        { label => 'total-dead', nlabel => 'systemd.services.dead.count', set => {
                key_values => [ { name => 'dead' }, { name => 'total' } ],
                output_template => 'Total Dead: %s',
                perfdatas => [
                    { label => 'total_dead', value => 'dead', template => '%s', 
                      min => 0, max => 'total' },
                ],
            }
        },
        { label => 'total-exited', nlabel => 'systemd.services.exited.count', set => {
                key_values => [ { name => 'exited' }, { name => 'total' } ],
                output_template => 'Total Exited: %s',
                perfdatas => [
                    { label => 'total_exited', value => 'exited', template => '%s', 
                      min => 0, max => 'total' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{sc} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'load' }, { name => 'active' },  { name => 'sub' }, { name => 'boot' }, { name => 'display' } ],
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
    
    $options{options}->add_options(arguments => { 
        'hostname:s'         => { name => 'hostname' },
        'remote'             => { name => 'remote' },
        'ssh-option:s@'      => { name => 'ssh_option' },
        'ssh-path:s'         => { name => 'ssh_path' },
        'ssh-command:s'      => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'          => { name => 'timeout', default => 30 },
        'sudo'               => { name => 'sudo' },
        'command:s'          => { name => 'command', default => 'systemctl' },
        'command-path:s'     => { name => 'command_path' },
        'command-options:s'  => { name => 'command_options', default => '-a --no-pager --no-legend' },
        'command-options2:s' => { name => 'command_options2', default => 'list-unit-files --no-pager --no-legend' },
        'filter-name:s'      => { name => 'filter_name' },
        'warning-status:s'   => { name => 'warning_status', default => '' },
        'critical-status:s'  => { name => 'critical_status', default => '%{active} =~ /failed/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_sc_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    $self->{global} = { running => 0, exited => 0, failed => 0, dead => 0, total => 0 };
    $self->{sc} = {};
    #auditd.service                                                        loaded    active   running Security Auditing Service
    #avahi-daemon.service                                                  loaded    active   running Avahi mDNS/DNS-SD Stack
    #brandbot.service                                                      loaded    inactive dead    Flexible Branding Service
    while ($stdout =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/msig) {
        my ($name, $load, $active, $sub) = ($1, $2, $3, lc($4));
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{sc}->{$name} = { display => $name, load => $load, active => $active, sub => $sub, boot => '-' };
        $self->{global}->{$sub} += 1 if (defined($self->{global}->{$sub}));
        $self->{global}->{total} += 1;
    }

    if (scalar(keys %{$self->{sc}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No service found.");
        $self->{output}->option_exit();
    }

    ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options2}
    );
    #runlevel4.target                              enabled 
    #runlevel5.target                              static  
    #runlevel6.target                              disabled
    while ($stdout =~ /^(.*?)\s+(\S+)\s*$/msig) {
        my ($name, $boot) = ($1, $2);
        next if (!defined($self->{sc}->{$name}));
        $self->{sc}->{$name}->{boot} = $boot;
    }
}

1;

__END__

=head1 MODE

Check systemd services status.

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

Command to get information (Default: 'systemctl').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-a --no-pager --no-legend').

=item B<--command-options2>

Command options (Default: 'list-unit-files --no-pager --no-legend').

=item B<--filter-name>

Filter service name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-running', 'total-dead', 'total-exited',
'total-failed'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{active}, %{sub}, %{load}, %{boot}

=item B<--critical-status>

Set critical threshold for status (Default: '%{active} =~ /failed/i').
Can used special variables like: %{display}, %{active}, %{sub}, %{load}, %{boot}

=back

=cut
