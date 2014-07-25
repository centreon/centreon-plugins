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

package storage::hp::p2000::xmlapi::mode::components::enclosure;

use strict;
use warnings;

my @conditions = (
    ['^degraded$' => 'WARNING'],
    ['^failed$' => 'CRITICAL'],
    ['^(unknown|not available)$' => 'UNKNOWN'],
);

my %health = (
    0 => 'ok',
    1 => 'degraded',
    2 => 'failed',
    3 => 'unknown',
    4 => 'not available',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking enclosures");
    $self->{components}->{enclosure} = {name => 'enclosures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'enclosure'));
    
    my $results = $self->{p2000}->get_infos(cmd => 'show enclosures', 
                                            base_type => 'enclosures',
                                            key => 'durable-id',
                                            properties_name => '^health-numeric|health-reason$');
    foreach my $enc_id (keys %$results) {
        next if ($self->check_exclude(section => 'enclosure', instance => $enc_id));
        $self->{components}->{enclosure}->{total}++;
        
        my $state = $health{$results->{$enc_id}->{'health-numeric'}};
        
        $self->{output}->output_add(long_msg => sprintf("enclosure '%s' status is %s.",
                                                        $enc_id, $state)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("enclosure '%s' status is %s (reason: %s)",
                                                        $enc_id, $state, $health{$results->{$enc_id}->{'health-reason'}}));
                last;
            }
        }
    }
}

1;