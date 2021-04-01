#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::idrac::snmp::mode::components::systembattery;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_state);

my $mapping = {
    systemBatteryStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.50.1.4', map => \%map_state },
    systemBatteryStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.50.1.5', map => \%map_status },
    systemBatteryLocationName   => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.50.1.7' }
};
my $oid_systemBatteryTableEntry = '.1.3.6.1.4.1.674.10892.5.4.600.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_systemBatteryTableEntry,
        start => $mapping->{systemBatteryStateSettings}->{oid},
        end => $mapping->{systemBatteryLocationName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking system batteries");
    $self->{components}->{systembattery} = {name => 'system batteries', total => 0, skip => 0};
    return if ($self->check_filter(section => 'systembattery'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_systemBatteryTableEntry}})) {
        next if ($oid !~ /^$mapping->{systemBatteryStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_systemBatteryTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'systembattery', instance => $instance));
        $self->{components}->{systembattery}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "system battery '%s' status is '%s' [instance = %s] [state = %s]",
                $result->{systemBatteryLocationName},
                $result->{systemBatteryStatus}, $instance, 
                $result->{systemBatteryStateSettings}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'systembattery.state', value => $result->{systemBatteryStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "System battery '%s' state is '%s'", $result->{systemBatteryLocationName}, $result->{systemBatteryStateSettings}
                )
            );
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'systembattery.status', value => $result->{systemBatteryStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "System battery '%s' status is '%s'", $result->{systemBatteryLocationName}, $result->{systemBatteryStatus}
                )
            );
        }
    }
}

1;
