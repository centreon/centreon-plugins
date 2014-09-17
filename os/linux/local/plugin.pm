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

package os::linux::local::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'cpu'              => 'os::linux::local::mode::cpu',
                         'cpu-detailed'     => 'os::linux::local::mode::cpudetailed',
                         'cmd-return'       => 'os::linux::local::mode::cmdreturn',
                         'connections'      => 'os::linux::local::mode::connections',
                         'diskio'           => 'os::linux::local::mode::diskio',
                         'files-size'       => 'os::linux::local::mode::filessize',
                         'files-date'       => 'os::linux::local::mode::filesdate',
                         'inodes'           => 'os::linux::local::mode::inodes',
                         'load'             => 'os::linux::local::mode::loadaverage',
                         'list-interfaces'  => 'os::linux::local::mode::listinterfaces',
                         'list-partitions'  => 'os::linux::local::mode::listpartitions',
                         'list-storages'    => 'os::linux::local::mode::liststorages',
                         'memory'           => 'os::linux::local::mode::memory',
                         'packet-errors'    => 'os::linux::local::mode::packeterrors',
                         'paging'           => 'os::linux::local::mode::paging',
                         'process'          => 'os::linux::local::mode::process',
                         'storage'          => 'os::linux::local::mode::storage',
                         'swap'             => 'os::linux::local::mode::swap',
                         'traffic'          => 'os::linux::local::mode::traffic',
                         'uptime'           => 'os::linux::local::mode::uptime',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Linux through local commands (the plugin can use SSH).

=cut
