###############################################################################
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
# Author : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package apps::protocols::ldap::mode::login;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use apps::protocols::ldap::lib::ldap;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"               => { name => 'hostname' },
         "ldap-connect-options:s@"  => { name => 'ldap_connect_options' },
         "ldap-starttls-options:s@" => { name => 'ldap_starttls_options' },
         "ldap-bind-options:s@"     => { name => 'ldap_bind_options' },
         "tls"                      => { name => 'use_tls' },
         "username:s"   => { name => 'username' },
         "password:s"   => { name => 'password' },
         "warning:s"    => { name => 'warning' },
         "critical:s"   => { name => 'critical' },
         "timeout:s"    => { name => 'timeout', default => '30' },
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    apps::protocols::ldap::lib::ldap::connect($self, connection_exit => 'critical');  
    apps::protocols::ldap::lib::ldap::quit();

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Response time %.3f second(s)", $timeelapsed));
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Connection (also login) to an LDAP Server.
LDAP Control are not still managed.

=over 8

=item B<--hostname>

IP Addr/FQDN of the ldap host

=item B<--ldap-connect-options>

Add custom ldap connect options:

=over 16

=item B<Set SSL connection>

--ldap-connect-options='scheme=ldaps'

=item B<Set LDAP version 2>

--ldap-connect-options='version=2'

=back

=item B<--ldap-starttls-options>

Add custom start tls options (need --tls option):

=over 16

=item B<An example>

--ldap-starttls-options='verify=none'

=back

=item B<--ldap-bind-options>

Add custom bind options (can force noauth) (not really useful now).

=item B<--username>

Specify username for authentification (can be a DN)

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning>

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=back

=cut
