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

package network::hp::procurve::mode::components::sensor;

use strict;
use warnings;

my %map_status = (
    1 => 'unknown', 
    2 => 'bad', 
    3 => 'warning', 
    4 => 'good',
    5 => 'not present',
);
my %object_map = (
    '.1.3.6.1.4.1.11.2.3.7.8.3.1' => 'power supply', #icfPowerSupplySensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.2' => 'fan',          #icfFanSensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.3' => 'temperature',  #icfTemperatureSensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.4' => 'future slot',  #icfFutureSlotSensor
);

my $mapping = {
    hpicfSensorObjectId => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.2', map => \%object_map },
    hpicfSensorStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.4', map => \%map_status },
    hpicfSensorDescr => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.7' },
};
my $oid_hpicfSensorEntry = '.1.3.6.1.4.1.11.2.14.11.1.2.6.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_hpicfSensorEntry };
}

sub check {
    my ($self) = @_;

    
    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'sensor'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hpicfSensorEntry}})) {
        next if ($oid !~ /^$mapping->{hpicfSensorStatus}->{oid}\.(.*)$/);
        my $instance_mapping = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hpicfSensorEntry}, instance => $instance_mapping);
        my $instance = $result->{hpicfSensorObjectId} . '.' . $instance_mapping;
        
        next if ($self->check_exclude(section => 'sensor', instance => $instance));
        next if ($result->{hpicfSensorStatus} =~ /not present/i && 
                 $self->absent_problem(section => 'sensor', instance => $instance));
        $self->{components}->{sensor}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("%s sensor '%s' state is %s [instance: %s].",
                                    $result->{hpicfSensorObjectId}, $instance, $result->{hpicfSensorStatus}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'sensor', value => $result->{hpicfSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("%s sensor '%s' state is %s", 
                                                        $result->{hpicfSensorObjectId}, $instance, $result->{hpicfSensorStatus}));
        }
    }
}

1;