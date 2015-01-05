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

package apps::asterisk::mode::getdata;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

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
                                  "command:s"         => { name => 'command' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options' },
                                  "trunkname:s"       => { name => 'trunkname' },
                                  "filter-name:s"     => { name => 'filter_name', },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options},
                                                  trunkname => $self->{option_results}->{trunkname});
    my @lines = split /\n/, $stdout;
    # Header not needed
    #shift @lines;
    foreach my $line (@lines) {        
        next if ($line !~ /^(.*): (.*) \((.*)\)/);
        my ($trunkname, $trunkstatus, $trunkvalue) = ($1, $2, $3);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $trunkname !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping trunk '" . $trunkname . "': no matching filter name");
            next;
        }
        #####
        # test
        #####
        if ($trunkname eq '009900524')
        {
        $self->{result}->{$trunkname} = {name => $trunkname, status => $trunkstatus, value => $trunkvalue};
        }
        else
        {
        $self->{result}->{$trunkname} = {name => $trunkname, status => 'Unknown', value => $trunkvalue};
        }
    }
}

sub run {
    my ($self, %options) = @_;
    my $msg;
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Everything is OK');
    $self->manage_selection();

    foreach my $name (sort(keys %{$self->{result}})) {
        $msg = sprintf("Trunk: %s %s", $self->{result}->{$name}->{name}, $self->{result}->{$name}->{status});
        $self->{output}->perfdata_add(label => $self->{result}->{$name}->{name},
                                  value => $self->{result}->{$name}->{value},
                                  #warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1'),
                                  #critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1'),
                                  min => 0);
        if (!$self->{output}->is_status(value => $self->{result}->{$name}->{status}, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $self->{result}->{$name}->{status},
                                        short_msg => $msg);
        } 
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         );
    }
}

1;

__END__

=head1 MODE

List partitions.

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

Command to get information (Default: 'cat').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '/proc/partitions 2>&1').

=item B<--filter-name>

Filter partition name (regexp can be used).

=back

=cut