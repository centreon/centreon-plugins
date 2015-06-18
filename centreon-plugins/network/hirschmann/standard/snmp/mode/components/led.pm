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

package network::hirschmann::standard::snmp::mode::components::led;

use strict;
use warnings;

my %map_led_status = (
    1 => 'off', 
    2 => 'green',
    3 => 'yellow',
    4 => 'red',
);

# In MIB 'hmpriv.mib'
my $oid_hmLEDGroup = '.1.3.6.1.4.1.248.14.1.1.35';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_hmLEDGroup };
}

sub check_led {
    my ($self, %options) = @_;

    my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$oid_hmLEDGroup}, instance => '0');
    foreach my $name (sort keys %{$options{mapping}}) {
        next if (!defined($result->{$name}));
        
        $options{mapping}->{$name}->{oid} =~ /\.(\d+)$/;
        my $instance = $1;

        next if ($self->check_exclude(section => 'led', instance => $instance));
        $self->{components}->{led}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Led '%s' status is %s [instance: %s].",
                                    $instance, $result->{$name},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'led', value => $result->{$name});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Led '%s' status is %s",
                                                             $instance, $result->{$name}));
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking leds");
    $self->{components}->{led} = {name => 'leds', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'led'));

    my $mapping;
    if (defined($self->{results}->{$oid_hmLEDGroup}->{$oid_hmLEDGroup . '.1.1.0'})) {
        $mapping = {
            hmLEDRSPowerSupply => { oid => '.1.3.6.1.4.1.248.14.1.1.35.1.1', map => \%map_led_status, desc => 'PowerSupply' },
            hmLEDRStandby => { oid => '.1.3.6.1.4.1.248.14.1.1.35.1.2', map => \%map_led_status, desc => 'Standby' },
            hmLEDRSRedundancyManager => { oid => '.1.3.6.1.4.1.248.14.1.1.35.1.3', map => \%map_led_status, desc => 'RedundancyManager' },
            hmLEDRSFault => { oid => '.1.3.6.1.4.1.248.14.1.1.35.1.4', map => \%map_led_status, desc => 'Fault' },
        };
    } elsif (defined($self->{results}->{$oid_hmLEDGroup}->{$oid_hmLEDGroup . '.2.1.0'})) {
        $mapping = {
            hmLEDOctPowerSupply1 => { oid => '.1.3.6.1.4.1.248.14.1.1.35.2.1', map => \%map_led_status, desc => 'PowerSupply1' },
            hmLEDOctPowerSupply2 => { oid => '.1.3.6.1.4.1.248.14.1.1.35.2.2', map => \%map_led_status, desc => 'PowerSupply2' },
            hmLEDOctRedundancyManager => { oid => '.1.3.6.1.4.1.248.14.1.1.35.2.3', map => \%map_led_status, desc => 'RedundancyManager' },
            hmLEDOctFault => { oid => '.1.3.6.1.4.1.248.14.1.1.35.2.4', map => \%map_led_status, desc => 'Fault' },
        };
    } elsif (defined($self->{results}->{$oid_hmLEDGroup}->{$oid_hmLEDGroup . '.3.1.0'})) {
        $mapping = {
            hmLEDRSRPowerSupply => { oid => '.1.3.6.1.4.1.248.14.1.1.35.3.1', map => \%map_led_status, desc => 'PowerSupply' },
            hmLEDRSRStandby => { oid => '.1.3.6.1.4.1.248.14.1.1.35.3.2', map => \%map_led_status, desc => 'Standby' },
            hmLEDRSRRedundancyManager => { oid => '.1.3.6.1.4.1.248.14.1.1.35.3.3', map => \%map_led_status, desc => 'RedundancyManager' },
            hmLEDRSRFault => { oid => '.1.3.6.1.4.1.248.14.1.1.35.3.4', map => \%map_led_status, desc => 'Fault' },
            hmLEDRSRRelay1 => { oid => '.1.3.6.1.4.1.248.14.1.1.35.3.5', map => \%map_led_status, desc => 'Relay1' },
            hmLEDRSRRelay2 => { oid => '.1.3.6.1.4.1.248.14.1.1.35.3.6', map => \%map_led_status, desc => 'Relay2' },
        };
    } else {
        return ;
    }
    
    check_led($self, mapping => $mapping);
}

1;