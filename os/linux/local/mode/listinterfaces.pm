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

package os::linux::local::mode::listinterfaces;

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
                                  "command:s"         => { name => 'command', default => 'ifconfig' },
                                  "command-path:s"    => { name => 'command_path', default => '/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '-a 2>&1' },
                                  "filter-name:s"     => { name => 'filter_name', },
                                  "filter-state:s"    => { name => 'filter_state', },
                                  "no-loopback"       => { name => 'no_loopback', },
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
                                                  command_options => $self->{option_results}->{command_options});
    while ($stdout =~ /^(\S+)(.*?)(\n\n|\n$)/msg) {
        my ($interface_name, $values) = ($1, $2);
        my $states = '';
        $states .= 'R' if ($values =~ /RUNNING/ms);
        $states .= 'U' if ($values =~ /UP/ms);
        
        next if (defined($self->{option_results}->{no_loopback}) && $values =~ /LOOPBACK/ms);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                 $interface_name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
                 $states !~ /$self->{option_results}->{filter_state}/);
        
        $self->{result}->{$interface_name} = {state => $states};
    }    
}

sub run {
    my ($self, %options) = @_;
	
    $self->manage_selection();
    my $interfaces_display = '';
    my $interfaces_display_append = '';
    foreach my $name (sort(keys %{$self->{result}})) {
        $interfaces_display .= $interfaces_display_append . 'name = ' . $name . ' [state = ' . $self->{result}->{$name}->{state} . ']';
        $interfaces_display_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List interfaces: ' . $interfaces_display);
    $self->{output}->display(nolabel => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         state => $self->{result}->{$name}->{state}
                                         );
    }
}

1;

__END__

=head1 MODE

List storages.

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

Command to get information (Default: 'ifconfig').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/sbin').

=item B<--command-options>

Command options (Default: '-a 2>&1').

=item B<--filter-name>

Filter interface name (regexp can be used).

=item B<--filter-state>

Filter state (regexp can be used).
Can be: 'R' (running), 'U' (up).

=item B<--no-loopback>

Don't display loopback interfaces.

=back

=cut