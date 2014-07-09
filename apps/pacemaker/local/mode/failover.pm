################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package apps::pacemaker::local::mode::failover;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"              => { name => 'hostname' },
                                  "remote"                  => { name => 'remote' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "sudo"                    => { name => 'sudo' },
                                  "command:s"               => { name => 'command', default => 'crm_mon' },
                                  "command-path:s"          => { name => 'command_path', default => '/usr/sbin' },
                                  "command-options:s"       => { name => 'command_options', default => '-1 -r -f 2>&1' },
                                  "warning"                 => { name => 'warning', },
                                  "resources:s"             => { name => 'resources', },
                                  "sticky:i"                => { name => 'sticky', default => 3600 },
                                  "show-cache"              => { name => 'show_cache' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    $self->{threshold} = 'CRITICAL';
    $self->{resources_check} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{warning})) {
        $self->{threshold} = 'WARNING';
    }
    if (defined($self->{option_results}->{resources})) {
        foreach my $rsc_name (split(/,/, $self->{option_results}->{resources})) {
            if (defined($rsc_name) && $rsc_name ne '') {
                $self->{resources_check}->{$rsc_name} = 1;
            }
        }
    }
    $self->{statefile_value}->check_options(%options);
}

sub parse_output {
    my ($self, %options) = @_;

    $self->{statefile_value}->read(statefile => 'pacemaker_' . $self->{mode} . '_' . (defined($self->{hostname}) ? md5_hex($self->{hostname}) : 'local') . '_' .(defined($self->{option_results}->{resources}) ? md5_hex($self->{option_results}->{resources}) : md5_hex('all')));
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_value}->get_string_content());
        $self->{output}->option_exit();
    }
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    my $sticky = $self->{statefile_value}->get(name => 'sticky');
   
    my $stopped_resources = 0;
    my $moved_resources = 0;

    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    
    if (defined($sticky) && ($new_datas->{last_timestamp} - $sticky < $self->{option_results}->{sticky})) {
        $self->{output}->output_add(severity => $self->{threshold},
                                    short_msg => $self->{statefile_value}->get(name => 'last_short_output'));

        $self->{output}->output_add(long_msg => $self->{statefile_value}->get(name => 'last_long_output'));
        
        $self->{output}->perfdata_add(label => "stopped_resources",
                                      value => $self->{statefile_value}->get(name => 'stopped_resources'),
                                      min => 0);

        $self->{output}->perfdata_add(label => "moved_resources",
                                      value => $self->{statefile_value}->get(name => 'moved_resources'),
                                      min => 0);
        $self->{output}->display();
        $self->{output}->exit();
    }
 
    my @standby;
    foreach my $line (split /\n/, $options{crm_out}) {
        if ($line =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+Started\s+([0-9a-zA-Z_\-]+)/) {
            # Check Resources pos
            $new_datas->{$1} = $2;
            $new_datas->{sticky} = $new_datas->{last_timestamp};
            my $old_owner = $self->{statefile_value}->get(name => $1);
            if ((defined($self->{resources_check}->{$1}))
                || (!defined($self->{option_results}->{resources}))) {
                if(defined($old_owner) && ($old_owner ne $2)){
                    $moved_resources++;
                    $self->{output}->output_add(severity => $self->{threshold},
                                                short_msg => 'Resource ' . $1 . ' moved');
                    $self->{output}->output_add(long_msg => 'Resource ' . $1 . ' moved from ' . $old_owner . ' to ' . $2);
                }
            }
        } elsif ($line =~ /\s*([0-9a-zA-Z_\-]+)\s+\(\S+\)\:\s+Stopped/) {
            $stopped_resources++;
            $self->{output}->output_add(severity => $self->{threshold}, 
                                        short_msg => 'Resource ' .  $1 . ' stopped');
        } elsif ($line =~ m/\s*stopped\:\s*\[(.*)\]/i) {
            # Check Master/Slave stopped
            $stopped_resources++;
            $self->{output}->output_add(severity => $self->{threshold}, 
                                        short_msg => 'Resource ' . $1 . ' stopped');
        }
    }

    if ($self->{output}->is_status(value => $self->{output}->get_litteral_status(), compare => 'ok', litteral => 1)) {
        $new_datas->{sticky} = 0;
        if (defined($old_timestamp)) {
            $self->{output}->output_add(severity => 'OK',
                                        short_msg => "Cluster is OK");
        }
    }

    $self->{output}->perfdata_add(label => "stopped_resources",
                                  value => $stopped_resources,
                                  min => 0);

    $self->{output}->perfdata_add(label => "moved_resources",
                                  value => $moved_resources,
                                  min => 0);

    $new_datas->{last_short_output} = $self->{output}-> {global_short_concat_outputs}->{$self->{threshold}};  
    if (scalar(@{$self->{output}->{global_long_output}})) {
        $new_datas->{last_long_output} = join("\n", @{$self->{output}->{global_long_output}});
    }
    $new_datas->{stopped_resources} = $stopped_resources;
    $new_datas->{moved_resources} = $moved_resources;

    $self->{statefile_value}->write(data => $new_datas);
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    $self->parse_output(crm_out => $stdout);
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check if some resources have migrated by Cluster Resource Manager (need 'crm_mon' command).
Should be executed on a cluster node.

=over 8

=item B<--warning>

If failed Nodes, stopped Resources detected or Standby Nodes sends Warning instead of Critical (default)
as long as there are no other errors and there is Quorum.

=item B<--resources>

Resources to query (format: <rsc_name>,<rsc_name>,...)

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

Command to get information (Default: 'crm_mon').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: '-1 -r -f 2>&1').

=item B<--show-cache>

Display cache resource datas.

=back

=cut
