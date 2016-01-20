#
# Copyright 2016 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hmLEDGroup };
}

sub check_led {
    my ($self, %options) = @_;

    my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$oid_hmLEDGroup}, instance => '0');
    foreach my $name (sort keys %{$options{mapping}}) {
        next if (!defined($result->{$name}));
        
        $options{mapping}->{$name}->{oid} =~ /\.(\d+)$/;
        my $instance = $1;

        next if ($self->check_filter(section => 'led', instance => $instance));
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
    return if ($self->check_filter(section => 'led'));

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