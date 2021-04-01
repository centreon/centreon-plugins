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

package hardware::server::ibm::bladecenter::snmp::mode::components::blade;

use strict;
use warnings;

my %map_blade_health_state = (
    0 => 'unknown',
    1 => 'good',
    2 => 'warning',
    3 => 'critical',
    4 => 'kernelMode',
    5 => 'discovering',
    6 => 'commError',
    7 => 'noPower',
    8 => 'flashing',
    9 => 'initFailure',
    10 => 'insufficientPower',
    11 => 'powerDenied',
);
my %map_blade_exists = (
    0 => 'false',
    1 => 'true',
);
my %map_blade_power_state = (
    0 => 'off',
    1 => 'on',
    3 => 'standby',
    4 => 'hibernate',
);

# In MIB 'mmblade.mib' and 'cme.mib'
my $mapping = {
    bladeId => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.2' },
    bladeExists => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.3', map => \%map_blade_exists  },
    bladePowerState => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.4', map => \%map_blade_power_state },
    bladeHealthState => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.5', map => \%map_blade_health_state },
    bladeName => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.6' },
};
my $oid_bladeSystemStatusEntry = '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_bladeSystemStatusEntry, start => $mapping->{bladeId}->{oid}, end => $mapping->{bladeName}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking blades");
    $self->{components}->{blade} = {name => 'blades', total => 0, skip => 0};
    return if ($self->check_filter(section => 'blade'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_bladeSystemStatusEntry}})) {
        next if ($oid !~ /^$mapping->{bladeExists}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_bladeSystemStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'blade', instance => $result->{bladeId}));
        if ($result->{bladeExists} =~ /false/i) {
            $self->{output}->output_add(long_msg => "skipping blade '" . $instance . "' : not exits"); 
            next;
        }
        $self->{components}->{blade}->{total}++;
        $result->{bladeName} = defined($result->{bladeName}) ? $result->{bladeName} : '-';
        
        if ($result->{bladePowerState} =~ /off/) {
            $self->{output}->output_add(long_msg => sprintf("Blade '%s/%s' power state is %s", 
                                                            $result->{bladeName}, $result->{bladeId}, $result->{bladePowerState},
                                                            ));
            next;
        }
        
        $self->{output}->output_add(long_msg => sprintf("Blade '%s/%s' state is %s [power state: %s]", 
                                    $result->{bladeName}, $result->{bladeId}, $result->{bladeHealthState}, $result->{bladePowerState},
                                    ));
        my $exit = $self->get_severity(section => 'blade', value => $result->{bladeHealthState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Blade '%s/%s' state is %s", 
                                                             $result->{bladeName}, $result->{bladeId}, $result->{bladeHealthState}));
        }
    }
}

1;