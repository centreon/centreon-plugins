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

package hardware::server::sun::mgmt_cards::plugin;

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
                         'show-faulty'      => 'hardware::server::sun::mgmt_cards::mode::showfaulty',
                         'showfaults'       => 'hardware::server::sun::mgmt_cards::mode::showfaults',
                         'showstatus'       => 'hardware::server::sun::mgmt_cards::mode::showstatus',
                         'showboards'       => 'hardware::server::sun::mgmt_cards::mode::showboards',
                         'showenvironment'  => 'hardware::server::sun::mgmt_cards::mode::showenvironment',
                         'environment-v8xx'  => 'hardware::server::sun::mgmt_cards::mode::environmentv8xx',
                         'environment-v4xx'  => 'hardware::server::sun::mgmt_cards::mode::environmentv4xx',
                         'environment-sf2xx'  => 'hardware::server::sun::mgmt_cards::mode::environmentsf2xx',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check a variety of Sun Hardware through management cards:
- mode 'show-faulty': ILOM (T3-x, T4-x, T5xxx) (in ssh with 'plink' command) ;
- mode 'showfaults': ALOM4v (in T1xxx, T2xxx) (in ssh with 'plink' command) ;
- mode 'showstatus': XSCF (Mxxxx - M3000, M4000, M5000,...) (in ssh with 'plink' command) ;
- mode 'showboards': ScApp (SFxxxx - sf6900, sf6800, sf3800,...) (in telnet with Net::Telnet) ;
- mode 'showenvironment': ALOM (v240, v440, v245,...) (in telnet with Net::Telnet or in ssh with 'plink' command) ;
- mode 'environment-v8xx': RSC cards (v890, v880) (in telnet with Net::Telnet) ;
- mode 'environment-v4xx': RSC cards (v480, v490) (in telnet with Net::Telnet) ;
- mode 'environment-sf2xx': RSC cards (sf280) (in telnet with Net::Telnet).

=cut
