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

package hardware::server::huawei::ibmc::snmp::mode::components::psu;

use strict;
use warnings;

my %map_status = (
    1 => 'ok',
    2 => 'minor',
    3 => 'major',
    4 => 'critical',
    5 => 'absence',
    6 => 'unknown',
);

my %map_installation_status = (
    1 => 'absence',
    2 => 'presence',
    3 => 'unknown',
);

my $mapping = {
    powerSupplyPowerRating  => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.6.50.1.6' },
    powerSupplyStatus       => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.6.50.1.7', map => \%map_status },
    powerSupplyInputPower   => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.6.50.1.8' },
    powerSupplyPresence     => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.6.50.1.9', map => \%map_installation_status },
    powerSupplyDevicename   => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.6.50.1.13' },
};
my $oid_powerSupplyDescriptionEntry = '.1.3.6.1.4.1.2011.2.235.1.1.6.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_powerSupplyDescriptionEntry,
        start => $mapping->{powerSupplyPowerRating}->{oid},
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerSupplyDescriptionEntry}})) {
        next if ($oid !~ /^$mapping->{powerSupplyStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerSupplyDescriptionEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{powerSupplyPresence} !~ /presence/);
        $self->{components}->{psu}->{total}++;

        if (defined($result->{powerSupplyInputPower}) && $result->{powerSupplyInputPower} =~ /[0-9]/ &&
            defined($result->{powerSupplyPowerRating}) && $result->{powerSupplyPowerRating} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu', instance => $instance, value => $result->{powerSupplyInputPower});
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' power is %s watts", $result->{powerSupplyDevicename}, $result->{powerSupplyInputPower}));
            }

            $self->{output}->perfdata_add(
                label => 'power', unit => 'W',
                nlabel => 'hardware.powersupply.power.watt',
                instances => $result->{powerSupplyDevicename},
                value => $result->{powerSupplyInputPower},
                warning => $warn,
                critical => $crit,
                min => 0,
                max => $result->{powerSupplyPowerRating}
            );
        }
        
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s' [instance = %s]",
                                    $result->{powerSupplyDevicename}, $result->{powerSupplyStatus}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{powerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $result->{powerSupplyDevicename}, $result->{powerSupplyStatus}));
        }
    }
}

1;
