################################################################################
# Copyright 2017 Centreon (http://www.centreon.com/)
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
# Authors : Yann Pilpré <yann.pilpre@ypsi.fr>
#
####################################################################################

# Chemin vers le mode
package network::radwin::snmp::mode::state;

# Bibliothèque nécessaire pour le mode
use base qw(centreon::plugins::mode);


# Bibliothèques nécessaires
use strict;
use warnings;

# Bibliothèque nécessaire pour certaines fonctions
use POSIX;
use Switch;
# Bibliothèque nécessaire pour utiliser un fichier de cache




sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    $self->{version} = '1.0';




    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

}

sub run {
  my ($self, %options) = @_;

  $self->{snmp} = $options{snmp};
  $self->{hostname} = $self->{snmp}->get_hostname();
  $self->{snmp_port} = $self->{snmp}->get_port();

  my $oid_AirSesState= ".1.3.6.1.4.1.4458.1000.1.5.5.0";

    my $snmpinfo  = $self->{snmp}->get_leef(oids => [ $oid_AirSesState ], nothing_quit => 1);
    my $state={};

switch ($snmpinfo->{$oid_AirSesState}) {
      
       case 1  { $state->{severity} = 'CRITICAL'; $state->{msg} = 'Session Down'} 
       case 2  { $state->{severity} = 'WARNING'; $state->{msg} = 'Basic Rate'}  
       case 3  { $state->{severity} = 'OK'; $state->{msg} = 'Active'}  
       case 4  { $state->{severity} = 'UNKNOWN'; $state->{msg} = 'Installation'}  
       case 5  { $state->{severity} = 'CRITICAL'; $state->{msg} = 'Scanning'}  
       case 6  { $state->{severity} = 'CRITICAL'; $state->{msg} = 'Probing'}  
       case 7  { $state->{severity} = 'WARNING'; $state->{msg} = 'Transmitting'}  
       case 8  { $state->{severity} = 'WARNING'; $state->{msg} = 'Active With Default Encryption Key'}  
       case 9  { $state->{severity} = 'UNKNOWN'; $state->{msg} = 'Installation With Default Encryption Key'}  
       case 10 { $state->{severity} = 'CRITICAL'; $state->{msg} = 'Bit Failed'}  
       case 11 { $state->{severity} = 'OK'; $state->{msg} = 'Active With Versions Mismatch'}  
       case 12 { $state->{severity} = 'UNKNOWN'; $state->{msg} = 'Installation With Versions Mismatch'}  
       case 13 { $state->{severity} = 'CRITICAL'; $state->{msg} = 'Inactive'}  
       case 14 { $state->{severity} = 'CRITICAL'; $state->{msg} = 'IDU Incompatible'} 
       case 15 { $state->{severity} = 'CRITICAL'; $state->{msg} = 'Spectrum Analysis'}  
	else { $state->{severity} = 'UNKNOWN'; $state->{msg} = 'State Unknown'} 
   
  
}
   $self->{output}->output_add(severity => $state->{severity},
                                    short_msg => $state->{msg});
   $self->{output}->display();
    $self->{output}->exit();
  }
1;
=head1 MODE

This Mode Checks RADWIN Radio Inteface State.
This Mode needs SNMP

=over 8
=back

=cut
