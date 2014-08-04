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

package hardware::server::cisco::ucs::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $thresholds;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($thresholds);

$thresholds = {
    presence => {
        0 => ['unknown', 'UNKNOWN'], 
        1 => ['empty', 'OK'], 
        10 => ['equipped', 'OK'], 
        11 => ['missing', 'WARNING'],
        12 => ['mismatch', 'WARNING'],
        13 => ['equippedNotPrimary', 'OK'],
        20 => ['equippedIdentityUnestablishable', 'WARNING'],
        21 => ['mismatchIdentityUnestablishable', 'WARNING'],
        30 => ['inaccessible', 'UNKNOWN'],
        40 => ['unauthorized', 'UNKNOWN'],
        100 => ['notSupported', 'WARNING'],
    },
    operability => {
        0 => ['unknown', 'UNKNOWN'], 
        1 => ['operable', 'OK'], 
        2 => ['inoperable', 'CRITICAL'], 
        3 => ['degraded', 'WARNING'],
        4 => ['poweredOff', 'WARNING'],
        5 => ['powerProblem', 'CRITICAL'],
        6 => ['removed', 'WARNING'],
        7 => ['voltageProblem', 'CRITICAL'],
        8 => ['thermalProblem', 'CRITICAL'],
        9 => ['performanceProblem', 'CRITICAL'],
        10 => ['accessibilityProblem', 'WARNING'],
        11 => ['identityUnestablishable', 'WARNING'],
        12 => ['biosPostTimeout', 'WARNING'],
        13 => ['disabled', 'OK'],
        51 => ['fabricConnProblem', 'WARNING'],
        52 => ['fabricUnsupportedConn', 'WARNING'],
        81 => ['config', 'OK'],
        82 => ['equipmentProblem', 'CRITICAL'],
        83 => ['decomissioning', 'WARNING'],
        84 => ['chassisLimitExceeded', 'WARNING'],
        100 => ['notSupported', 'WARNING'],
        101 => ['discovery', 'OK'],
        102 => ['discoveryFailed', 'WARNING'],
        104 => ['postFailure', 'WARNING'],
        105 => ['upgradeProblem', 'WARNING'],
        106 => ['peerCommProblem', 'WARNING'],
        107 => ['autoUpgrade', 'OK'],
    },
};

1;