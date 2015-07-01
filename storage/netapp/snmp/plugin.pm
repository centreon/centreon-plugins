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

package storage::netapp::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'aggregatestate'   => 'storage::netapp::snmp::mode::aggregatestate',
                         'cp-statistics'    => 'storage::netapp::snmp::mode::cpstatistics',
                         'cpuload'          => 'storage::netapp::snmp::mode::cpuload',
                         'diskfailed'       => 'storage::netapp::snmp::mode::diskfailed',
                         'fan'              => 'storage::netapp::snmp::mode::fan',
                         'filesys'          => 'storage::netapp::snmp::mode::filesys',
                         'list-filesys'     => 'storage::netapp::snmp::mode::listfilesys',
                         'global-status'    => 'storage::netapp::snmp::mode::globalstatus',
                         'ndmpsessions'     => 'storage::netapp::snmp::mode::ndmpsessions',
                         'nvram'            => 'storage::netapp::snmp::mode::nvram',
                         'partnerstatus'    => 'storage::netapp::snmp::mode::partnerstatus',
                         'psu'              => 'storage::netapp::snmp::mode::psu',
                         'qtree-usage'      => 'storage::netapp::snmp::mode::qtreeusage',
                         'share-calls'      => 'storage::netapp::snmp::mode::sharecalls',
                         'shelf'            => 'storage::netapp::snmp::mode::shelf',
                         'snapmirrorlag'    => 'storage::netapp::snmp::mode::snapmirrorlag',
                         'snapshotage'      => 'storage::netapp::snmp::mode::snapshotage',
                         'temperature'      => 'storage::netapp::snmp::mode::temperature',
                         'volumeoptions'    => 'storage::netapp::snmp::mode::volumeoptions',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Netapp in SNMP (Some Check needs ONTAP 8.x).

=cut
