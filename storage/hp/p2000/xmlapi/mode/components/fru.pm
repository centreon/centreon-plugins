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

package storage::hp::p2000::xmlapi::mode::components::fru;

use strict;
use warnings;

my @conditions = (
    ['^absent$' => 'WARNING'],
    ['^fault$' => 'CRITICAL'],
    ['^not available$' => 'UNKNOWN'],
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking frus");
    $self->{components}->{fru} = {name => 'frus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fru'));
    
    my $results = $self->{p2000}->get_infos(cmd => 'show frus', 
                                            base_type => 'enclosure-fru',
                                            key => 'part-number', 
                                            properties_name => '^(fru-status|fru-location)$');
    foreach my $part_number (keys %$results) {
        my $instance = $results->{$part_number}->{'fru-location'};
    
        next if ($self->check_exclude(section => 'fru', instance => $instance));
        $self->{components}->{fru}->{total}++;
        
        my $state = $results->{$part_number}->{'fru-status'};
        
        $self->{output}->output_add(long_msg => sprintf("fru '%s' status is %s.",
                                                        $instance, $state)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("fru '%s' status is %s",
                                                        $instance, $state));
                last;
            }
        }
    }
}

1;