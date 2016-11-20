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

package storage::emc::celerra::local::mode::getreason;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_overload_check_section_option} = 
        '^(controlstation|datamover)$';
    
    $self->{cb_hook2} = 'cmd_execute';
    
    $self->{thresholds} = {
        controlstation => [
            ['Primary Control Station', 'OK'], # 10
            ['Secondary Control Station', 'OK'], # 11
            ['Control Station is ready, but is not running NAS service', 'CRITICAL'], # 6
        ],
        datamover => [
            ['Reset (or unknown state)', 'WARNING'],
            ['DOS boot phase, BIOS check, boot sequence', 'WARNING'],
            ['SIB POST failures (that is, hardware failures)', 'CRITICAL'],
            ['DART is loaded on Data Mover, DOS boot and execution of boot.bat, boot.cfg', 'WARNING'],
            ['DART is ready on Data Mover, running, and MAC threads started', 'WARNING'],
            ['DART is in contact with Control Station box monitor', 'OK'],
            ['DART is in panic state', 'CRITICAL'],
            ['DART reboot is pending or in halted state', 'WARNING'],
            ['DART panicked and completed memory dump', 'CRITICAL'],
            ['DM Misc problems', 'CRITICAL'], # code 14
            ['Data Mover is flashing firmware. DART is flashing BIOS and/or POST firmware. Data Mover cannot be reset', 'CRITICAL'],
            ['Data Mover Hardware fault detected', 'CRITICAL'],
            ['DM Memory Test Failure. BIOS detected memory error', 'CRITICAL'],
            ['DM POST Test Failure. General POST error', 'CRITICAL'],
            ['DM POST NVRAM test failure. Invalid NVRAM content error', 'CRITICAL'],
            ['DM POST invalid peer Data Mover type', 'CRITICAL'],
            ['DM POST invalid Data Mover part number', 'CRITICAL'],
            ['DM POST Fibre Channel test failure. Error in blade Fibre connection', 'CRITICAL'],
            ['DM POST network test failure. Error in Ethernet controller', 'CRITICAL'],
            ['DM T2NET Error. Unable to get blade reason code due to management switch problems', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'storage::emc::celerra::local::mode::components';
    $self->{components_module} = ['controlstation', 'datamover'];
}

sub cmd_execute {
    my ($self, %options) = @_;
    
    ($self->{stdout}) = centreon::plugins::misc::execute(output => $self->{output},
                                                         options => $self->{option_results},
                                                         sudo => $self->{option_results}->{sudo},
                                                         command => $self->{option_results}->{command},
                                                         command_path => $self->{option_results}->{command_path},
                                                         command_options => $self->{option_results}->{command_options});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1);
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
                                  "command:s"         => { name => 'command', default => 'getreason' },
                                  "command-path:s"    => { name => 'command_path', default => '/nas/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '2>&1' },
                                });

    return $self;
}

1;

__END__

=head1 MODE

Check control stations and data movers status (use 'getreason' command).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'controlstation', 'datamover'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=datamover)
Can also exclude specific instance: --filter=datamover,slot_2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='datamover,CRITICAL,^(?!(normal)$)'

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'getreason').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/nas/sbin').

=item B<--command-options>

Command options (Default: '2>&1').

=back

=cut
    
