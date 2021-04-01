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

package os::solaris::local::mode::hwsas2ircu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"         => { name => 'hostname' },
                                  "remote"             => { name => 'remote' },
                                  "ssh-option:s@"      => { name => 'ssh_option' },
                                  "ssh-path:s"         => { name => 'ssh_path' },
                                  "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"          => { name => 'timeout', default => 30 },
                                  "sudo1"              => { name => 'sudo1' },
                                  "command1:s"         => { name => 'command1', default => 'metastat' },
                                  "command1-path:s"    => { name => 'command1_path', default => '/usr/sbin' },
                                  "command1-options:s" => { name => 'command1_options', default => '-c 2>&1' },
                                  "sudo2"              => { name => 'sudo2' },
                                  "command2:s"         => { name => 'command2', default => 'metadb' },
                                  "command2-path:s"    => { name => 'command2_path', default => '/usr/sbin' },
                                  "command2-options:s" => { name => 'command2_options', default => '2>&1' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo1},
                                                  command => $self->{option_results}->{command1},
                                                  command_path => $self->{option_results}->{command1_path},
                                                  command_options => $self->{option_results}->{command1_options});
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No problems on volumes");

    while (($stdout =~ /^\s*Index.*?\n.*?\n\s+(\d+)\s+/imsg)) {
        # Index    Type          ID      ID    Pci Address          Ven ID  Dev ID
        # -----  ------------  ------  ------  -----------------    ------  ------
        #   0     SAS2008     1000h    72h   00h:04h:00h:00h      1000h   0072h
        #
        #        Adapter      Vendor  Device                       SubSys  SubSys
        # Index    Type          ID      ID    Pci Address          Ven ID  Dev ID
        # -----  ------------  ------  ------  -----------------    ------  ------
        #   1     SAS2008     1000h    72h   00h:0bh:00h:00h      1000h   0072h
        #SAS2IRCU: Utility Completed Successfully.
        my $index = $1;
        my $stdout2 = centreon::plugins::misc::execute(output => $self->{output},
                                                       options => $self->{option_results},
                                                       sudo => $self->{option_results}->{sudo2},
                                                       command => $self->{option_results}->{command2},
                                                       command_path => $self->{option_results}->{command2_path},
                                                       command_options => sprintf($self->{option_results}->{command2_options}, $index));
        
        #IR Volume information
        #------------------------------------------------------------------------
        #IR volume 1
        #  Volume ID                               : 905
        #  Volume Name                             : test
        #  Status of volume                        : Okay (OKY)
        #  RAID level                              : RAID1
        #  Size (in MB)                            : 68664
        #  Physical hard disks                     :
        #  PHY[0] Enclosure#/Slot#                 : 1:2
        #  PHY[1] Enclosure#/Slot#                 : 1:3
        #------------------------------------------------------------------------
        #Physical device information
        
        if ($stdout2 =~ /^IR Volume information(.*)Physical device information/ims) {
            my @content = split(/\n/, $1);
            shift @content;
            my $volume_name = '';
            foreach my $line (@content) {
            
                next if ($line =~ /^---/);
            
                if ($line =~ /Volume Name\s+:\s+(.*)/i) {
                    $volume_name = $1;
                    $volume_name = centreon::plugins::misc::trim($volume_name);
                    next;
                }
            
                if ($line =~ /Status of volume\s+:\s+(.*)(\n|\()/i) {
                    my $status_volume = $1;
                    $status_volume = centreon::plugins::misc::trim($status_volume);
                    if ($status_volume !~ /Okay/i) {
                        $self->{output}->output_add(severity => 'CRITICAL', 
                                                    short_msg => "Volume 'volume_name' status is '$status_volume'");
                    }
                }
            }
        }
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Hardware Raid Status (use 'sas2ircu' command).

=over 8

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

=item B<--sudo1>

Use 'sudo' to execute the command.

=item B<--command1>

Command to get information (Default: 'sas2ircu').
Can be changed if you have output in a file.

=item B<--command1-path>

Command path (Default: '/usr/bin').

=item B<--command1-options>

Command options (Default: 'LIST 2>&1').

=item B<--sudo2>

Use 'sudo' to execute the command.

=item B<--command2>

Command to get information (Default: 'sas2ircu').
Can be changed if you have output in a file.

=item B<--command2-path>

Command path (Default: '/usr/bin').

=item B<--command2-options>

Command options (Default: '%s DISPLAY 2>&1').
!!! Modify it if you know what you do ;) !!!

=back

=cut
