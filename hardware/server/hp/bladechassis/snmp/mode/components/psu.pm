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

package hardware::server::hp::bladechassis::snmp::mode::components::psu;

use strict;
use warnings;

my %map_conditions = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
    4 => 'Weird!!!', # for blades it can return 4, which is NOT spesified in MIB
);

my %psu_status_map = (
    1  => 'noError',
    2  => 'generalFailure',
    3  => 'bistFailure',
    4  => 'fanFailure',
    5  => 'tempFailure',
    6  => 'interlockOpen',
    7  => 'epromFailed',
    8  => 'vrefFailed',
    9  => 'dacFailed',
    10 => 'ramTestFailed',
    11 => 'voltageChannelFailed',
    12 => 'orringdiodeFailed',
    13 => 'brownOut',
    14 => 'giveupOnStartup',
    15 => 'nvramInvalid',
    16 => 'calibrationTableInvalid',
);
my %inputline_status_map = (
    1 => 'noError',
    2 => 'lineOverVoltage',
    3 => 'lineUnderVoltage',
    4 => 'lineHit',
    5 => 'brownOut',
    6 => 'linePowerLoss',
);

my $mapping = {
    psu_status          => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.14', map => \%psu_status_map }, # cpqRackPowerSupplyStatus
    psu_serial          => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.5' }, # cpqRackPowerSupplySerialNum
    psu_part            => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.6' }, # cpqRackPowerSupplyPartNumber
    psu_spare           => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.7' }, # cpqRackPowerSupplySparePartNumber
    psu_inputlinestatus => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.15', map => \%inputline_status_map }, # cpqRackPowerSupplyInputLineStatus
    psu_condition       => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.17', map => \%map_conditions }, # cpqRackPowerSupplyCondition
    psu_pwrout          => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.10' }, # cpqRackPowerSupplyCurPwrOutput in Watts
    psu_intemp          => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.12' }, # cpqRackPowerSupplyIntakeTemp
    psu_exhtemp         => { oid => '.1.3.6.1.4.1.232.22.2.5.1.1.1.13' }, # cpqRackPowerSupplyExhaustTemp
};

sub check {
    my ($self) = @_;

    # We dont check 'cpqRackPowerEnclosureTable' (the overall power system status)
    # We check 'cpqRackPowerSupplyTable' (unitary)

    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "checking power supplies");
    return if ($self->check_filter(section => 'psu'));
    
    my $oid_cpqRackPowerSupplyPresent = '.1.3.6.1.4.1.232.22.2.5.1.1.1.16';
    
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackPowerSupplyPresent);
    return if (scalar(keys %$snmp_result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        $key =~ /^$oid_cpqRackPowerSupplyPresent\.(.*)$/;
        my $oid_end = $1;
        
        next if ($present_map{$snmp_result->{$key}} ne 'present' && 
                 $self->absent_problem(section => 'psu', instance => $oid_end));
        
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }

    $snmp_result = $self->{snmp}->get_leef(oids => \@get_oids);
    my $total_watts = 0;
    foreach (@oids_end) {
        my $psu_index = $_;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        next if ($self->check_filter(section => 'psu', instance => $psu_index));
        
        $total_watts += $result->{psu_pwrout};
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf("psu '%s' status is %s [serial: %s, part: %s, spare: %s] (input line status %s) (status %s).",
                $psu_index, $result->{psu_condition},
                $result->{psu_serial}, $result->{psu_part}, $result->{psu_spare},
                $result->{psu_inputlinestatus},
                $result->{psu_status}
            )
        );
        
        my $exit = $self->get_severity(label => 'default', section => 'psu', instance => $psu_index, value => $result->{psu_condition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("PSU '%s' status is %s",
                                           $psu_index, $result->{psu_condition}));
        }
        
        $self->{output}->perfdata_add(
            label => 'psu_power', unit => 'W',
            nlabel => 'hardware.powersupply.power.watt',
            instances => $psu_index,
            value => $result->{psu_pwrout}
        );
        if (defined($result->{psu_intemp}) && $result->{psu_intemp} != -1) {
            $self->{output}->perfdata_add(
                label => 'psu_temp', unit => 'C',
                nlabel => 'hardware.powersupply.temperature.celsius',
                instances => [$psu_index, 'intake'],
                value => $result->{psu_intemp}
            );
        }
        if (defined($result->{psu_exhtemp}) && $result->{psu_exhtemp} != -1) {
            $self->{output}->perfdata_add(
                label => 'psu_temp', unit => 'C',
                nlabel => 'hardware.powersupply.temperature.celsius',
                instances => [$psu_index, 'exhaust'],
                value => $result->{psu_exhtemp}
            );
        }
    }
    
    $self->{output}->perfdata_add(
        label => 'total_power', unit => 'W',
        nlabel => 'hardware.powersupply.power.watt',
        value => $total_watts
    );
}

1;
