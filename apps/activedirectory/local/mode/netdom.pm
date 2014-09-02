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

package apps::activedirectory::local::mode::netdom;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "domain:s"        => { name => 'domain', },
                                  "workstation:s"   => { name => 'workstation', default => '%COMPUTERNAME%' },
                                  "timeout:s"       => { name => 'timeout', default => 30 },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub netdom {
    my ($self, %options) = @_;

    my $netdom_cmd = 'netdom verify ';
    $netdom_cmd .= ' /Domain:' . $self->{option_results}->{domain} if (defined($self->{option_results}->{domain}) && $self->{option_results}->{domain} ne '');
    $netdom_cmd .= ' ' . $self->{option_results}->{workstation};
    
    my ($stdout, $exit_code) = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                          timeout => $self->{option_results}->{timeout},
                                                          command => $netdom_cmd . " 2>&1",
                                                          command_path => undef,
                                                          command_options => undef,
                                                          no_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Secure channel has been verified.');
    if ($exit_code != 0) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => 'Secure channel had a problem (see additional info).');
    }
}

sub run {
    my ($self, %options) = @_;

    $self->netdom();   
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the secure connection between a workstation and a domain controller (use 'netdom' command).

=over 8

=item B<--workstation>

Set the name of the workstation (Default: current hostname)

=item B<--domain>

Set the name of the domain (Default: current domain of the workstation)

=item B<--timeout>

Set timeout time for command execution (Default: 30 sec)

=back

=cut