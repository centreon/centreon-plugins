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

package storage::netapp::mode::components::psu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_enclChannelShelfAddr = '.1.3.6.1.4.1.789.1.21.1.2.1.3';
my $oid_enclPowerSuppliesPresent = '.1.3.6.1.4.1.789.1.21.1.2.1.13';
my $oid_enclPowerSuppliesFailed = '.1.3.6.1.4.1.789.1.21.1.2.1.15';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_enclPowerSuppliesPresent };
    push @{$options{request}}, { oid => $oid_enclPowerSuppliesFailed };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    for (my $i = 1; $i <= $self->{number_shelf}; $i++) {
        my $shelf_addr = $self->{shelf_addr}->{$oid_enclChannelShelfAddr . '.' . $i};
        my $present = $self->{results}->{$oid_enclPowerSuppliesPresent}->{$oid_enclPowerSuppliesPresent . '.' . $i};
        my $failed = $self->{results}->{$oid_enclPowerSuppliesFailed}->{$oid_enclPowerSuppliesFailed . '.' . $i};
        
        foreach my $num (split /,/, $present) {
            $num = centreon::plugins::misc::trim($num);
            next if ($num !~ /[0-9]/);
            
            next if ($self->check_exclude(section => 'psu', instance => $shelf_addr . '.' . $num));
            $self->{components}->{psu}->{total}++;

            my $status = 'ok';
            if ($failed =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'failed';
            }

            $self->{output}->output_add(long_msg => sprintf("Shelve '%s' PSU '%s' is '%s'", 
                                        $shelf_addr, $num, $status));
            my $exit = $self->get_severity(section => 'psu', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Shelve '%s' PSU '%s' is '%s'", $shelf_addr, $num, $status));
            }
        }
    }
}

1;
