###############################################################################
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Florian Asche <info@florian-asche.de>
#
####################################################################################

package apps::apcupsd::local::mode::outputvoltage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::apcupsd::local::mode::libgetdata;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"         => { name => 'hostname' },
                                  "remote"             => { name => 'remote' },
                                  "ssh-option:s@"      => { name => 'ssh_option' },
                                  "ssh-path:s"         => { name => 'ssh_path' },
                                  "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"          => { name => 'timeout', default => 30 },
                                  "sudo"               => { name => 'sudo' },
                                  "command:s"          => { name => 'command', default => 'apcaccess' },
                                  "command-path:s"     => { name => 'command_path', default => '/sbin/' },
                                  "command-options:s"  => { name => 'command_options', default => ' status ' },
                                  "command-options2:s" => { name => 'command_options2', default => ' 2>&1' },
                                  "apchost:s"          => { name => 'apchost', default => 'localhost' },
                                  "apcport:s"          => { name => 'apcport', default => '3551' },
                                  "searchpattern:s"    => { name => 'searchpattern', default => 'OUTPUTV' },
                                  "warning:s"          => { name => 'warning', default => '' },
                                  "critical:s"         => { name => 'critical', default => '' },
                                });
    return $self;
}

sub check_options {

    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{apchost})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an APC Host.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{apcport})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an APC Port.");
       $self->{output}->option_exit(); 
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
        
    my $result = apps::apcupsd::local::mode::libgetdata::getdata($self);
    my $exit = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf($self->{option_results}->{searchpattern} . ": %f", $result));

    $self->{output}->perfdata_add(label => $self->{option_results}->{searchpattern},
                                  value => $result,
                                  unit => "",
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
                                  );
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check apcupsd Status

=over 8

=item B<--apchost>

IP used by apcupsd

=item B<--apcport>

Port used by apcupsd

=item B<--warning>

Warning Threshold

=item B<--critical>

Critical Threshold

=back

=cut
