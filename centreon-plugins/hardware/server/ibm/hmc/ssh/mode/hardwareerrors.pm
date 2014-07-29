################################################################################
# Copyright 2005-2013 MERETHIS
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

package hardware::server::ibm::hmc::ssh::mode::hardwareerrors;

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
                                  "hostname:s"              => { name => 'hostname' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "sudo"                    => { name => 'sudo' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "hmc-command:s"           => { name => 'hmc_command', default => 'lssvcevents' },
                                  "retention:i"             => { name => 'retention' },
                                  "minutes"                 => { name => 'minutes' },
                                  "filter-status:s"         => { name => 'filter_status', default => 'open' },
                                  "filter-problem-nums:s"   => { name => 'filter_problem_nums' },
                                  "filter-system:s"         => { name => 'filter_system' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
       $self->{output}->option_exit(); 
    }
    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} !~ /^\d+$/) {
        $self->{output}->add_option_msg(short_msg => "Need to specify an integer as retention.");
        $self->{output}->option_exit();
    }
}

sub build_command {
    my ($self, %options) = @_;
    
    $self->{hmc_command} = $self->{option_results}->{hmc_command} . " -t hardware -F first_time~sys_name~text "; 
    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} ne '') {
        if (defined($self->{option_results}->{minutes})) {
            $self->{hmc_command} .= ' -i ' . $self->{option_results}->{retention};
        } else {
            $self->{hmc_command} .= ' -d ' . $self->{option_results}->{retention};
        }
    }

    if ($self->{option_results}->{filter_status} ne '' && (!defined($self->{option_results}->{filter_problem_nums}) || ($self->{option_results}->{filter_problem_nums} eq ''))) {
        $self->{hmc_command} .= ' --filter "status=' . $self->{option_results}->{filter_status} . '" ';
    } elsif ($self->{option_results}->{filter_status} ne '' && defined($self->{option_results}->{filter_problem_nums}) && $self->{option_results}->{filter_problem_nums} ne '') {
        $self->{hmc_command} .= ' --filter "status=' . $self->{option_results}->{filter_status} . ',problem_nums=' . $self->{option_results}->{filter_problem_nums} . '"';
    } elsif (defined($self->{option_results}->{filter_problem_nums}) && $self->{option_results}->{filter_problem_nums} ne '') {
        $self->{hmc_command} .= ' --filter "status=' . $self->{option_results}->{filter_problem_nums} . '"';
    }

    if (defined($self->{option_results}->{filter_system}) && $self->{option_results}->{filter_system} ne '') {
        $self->{hmc_command} .= ' -m ' . $self->{option_results}->{filter_system} . ' ';
    }
}

sub run {
    my ($self, %options) = @_;

    $self->build_command();
    $self->{option_results}->{remote} = 1;
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{hmc_command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});

    ######
    # Command treatment
    ######
    my @long_msg = split("\n", $stdout);
   
    if (defined($self->{option_results}->{retention}) and defined($self->{option_results}->{minutes})) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "No Problems on system since " . $self->{option_results}->{retention} . " minutes.");
    } elsif (defined($self->{option_results}->{retention})) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "No Problems on system since " . $self->{option_results}->{retention} . " days.");
    } else { 
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No Problems on system.");
    }

    foreach my $line (@long_msg){
        if ($line =~ /^(.*)~(.*)~(.*)$/) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "[$1][$2] $3");
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Hardware for system managed by HMC.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh').

=item B<--command-hmc>

Hmc command to list events (default: lssvcevents).

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--retention>

Retention of errors. If option --minutes is not specified, retention is in days.

=item B<--minutes>

Retention in minutes. Use with option --retention.

=item B<--filter-status>

Filter by status ("open" or "closed") (Default : open).

=item B<--filter-problem-nums>

Filter by problem number (several number can be specified, separated by coma).

=item B<--filter-system>

Filter by system. The name may either be the user-defined name for the managed system, or be in the form tttt-mmm*ssssssss, where tttt is the machine type, mmm is the model, and ssssssss is the serial number of the managed system

=back

=cut
