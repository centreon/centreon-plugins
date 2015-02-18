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

package storage::panzura::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'cpu-detailed'     => 'snmp_standard::mode::cpudetailed',
                         'cpu-cloud'        => 'storage::panzura::snmp::mode::cpucloud',
                         'diskio'           => 'snmp_standard::mode::diskio',
                         'disk-usage-cloud' => 'snmp_standard::mode::diskusage',
                         'disk-usage-local' => 'storage::panzura::snmp::mode::diskusagelocal',
                         'load'             => 'snmp_standard::mode::loadaverage',
                         'list-diskspath'   => 'snmp_standard::mode::listdiskspath',
                         'list-interfaces'  => 'snmp_standard::mode::listinterfaces',
                         'list-storages'    => 'snmp_standard::mode::liststorages',
                         'memory'           => 'storage::panzura::snmp::mode::memory',
                         'packet-errors'    => 'snmp_standard::mode::packeterrors',
                         'ratios'           => 'storage::panzura::snmp::mode::ratios',
                         'swap'             => 'snmp_standard::mode::swap',
                         'traffic'          => 'snmp_standard::mode::traffic',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Panzura storage in SNMP.

=cut
