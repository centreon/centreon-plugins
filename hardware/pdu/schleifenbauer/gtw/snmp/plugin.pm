################################################################################
## Copyright 2005-2015 MERETHIS
## Centreon is developped by : Julien Mathis and Romain Le Merlus under
## GPL Licence 2.0.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation ; either version 2 of the License.
##
## This program is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
## PARTICULAR PURPOSE. See the GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses>.
##
## Linking this program statically or dynamically with other modules is making a
## combined work based on this program. Thus, the terms and conditions of the GNU
## General Public License cover the whole combination.
##
## As a special exception, the copyright holders of this program give MERETHIS
## permission to link this program with independent modules to produce an executable,
## regardless of the license terms of these independent modules, and to copy and
## distribute the resulting executable under terms of MERETHIS choice, provided that
## MERETHIS also meet, for each linked independent module, the terms  and conditions
## of the license of that module. An independent module is a module which is not
## derived from this program. If you modify this program, you may extend this
## exception to your version of the program, but you are not obliged to do so. If you
## do not wish to do so, delete this exception statement from your version.
##
## For more information : contact@centreon.com
## Authors : Christophe De Loeul <cdeloeul@gmail.com>
##
#####################################################################################

package hardware::pdu::schleifenbauer::gtw::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);


sub new {
  my ($class, %options) = @_;
  my $self = $class->SUPER::new(package => __PACKAGE__, %options);
  bless $self, $class;
  # $options->{options} = options object

  # Version du plugin
  $self->{version} = '0.1';

  # Association des modes
  %{$self->{modes}} = (
                       # Nom du mode => Chemin vers le mode
                       'temperature'   => 'hardware::pdu::schleifenbauer::gtw::snmp::mode::temperature',
                       'humidity'   => 'hardware::pdu::schleifenbauer::gtw::snmp::mode::humidity',
                       'pdu-status'   => 'hardware::pdu::schleifenbauer::gtw::snmp::mode::pdustatus',
                       );

  return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Schleifenbauwer gateway trought SNMP.

=cut
