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

sub check {
    my ($self) = @_;

    # We dont check 'cpqRackPowerEnclosureTable' (the overall power system status)
    # We check 'cpqRackPowerSupplyTable' (unitary)

    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking power supplies");
    return if ($self->check_exclude(section => 'psu'));
    
    my $oid_cpqRackPowerSupplyPresent = '.1.3.6.1.4.1.232.22.2.5.1.1.1.16';
    my $oid_cpqRackPowerSupplyIndex = '.1.3.6.1.4.1.232.22.2.5.1.1.1.3';
    my $oid_cpqRackPowerSupplySerialNum = '.1.3.6.1.4.1.232.22.2.5.1.1.1.5';
    my $oid_cpqRackPowerSupplyPartNumber = '.1.3.6.1.4.1.232.22.2.5.1.1.1.6';
    my $oid_cpqRackPowerSupplySparePartNumber = '.1.3.6.1.4.1.232.22.2.5.1.1.1.7';
    my $oid_cpqRackPowerSupplyStatus = '.1.3.6.1.4.1.232.22.2.5.1.1.1.14';
    my $oid_cpqRackPowerSupplyInputLineStatus = '.1.3.6.1.4.1.232.22.2.5.1.1.1.15';
    my $oid_cpqRackPowerSupplyCondition = '.1.3.6.1.4.1.232.22.2.5.1.1.1.17';
    my $oid_cpqRackPowerSupplyCurPwrOutput = '.1.3.6.1.4.1.232.22.2.5.1.1.1.10'; # Watts
    my $oid_cpqRackPowerSupplyIntakeTemp = '.1.3.6.1.4.1.232.22.2.5.1.1.1.12';
    my $oid_cpqRackPowerSupplyExhaustTemp = '.1.3.6.1.4.1.232.22.2.5.1.1.1.13';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackPowerSupplyPresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /\.([0-9]+)$/;
        my $oid_end = $1;
        
        next if ($present_map{$result->{$key}} ne 'present' && 
                 $self->absent_problem(section => 'psu', instance => $oid_end));
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cpqRackPowerSupplyIndex . "." . $oid_end, $oid_cpqRackPowerSupplySerialNum . "." . $oid_end,
                $oid_cpqRackPowerSupplyPartNumber . "." . $oid_end, $oid_cpqRackPowerSupplySparePartNumber . "." . $oid_end,
                $oid_cpqRackPowerSupplyStatus . "." . $oid_end, $oid_cpqRackPowerSupplyInputLineStatus . "." . $oid_end,
                $oid_cpqRackPowerSupplyCondition . "." . $oid_end, $oid_cpqRackPowerSupplyCurPwrOutput . "." . $oid_end,
                $oid_cpqRackPowerSupplyIntakeTemp . "." . $oid_end, $oid_cpqRackPowerSupplyExhaustTemp . "." . $oid_end;
    }
    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    my $total_watts = 0;
    foreach (@oids_end) {
        my $psu_index = $result->{$oid_cpqRackPowerSupplyIndex . '.' . $_};
        my $psu_status = $result->{$oid_cpqRackPowerSupplyStatus . '.' . $_};
        my $psu_serial = $result->{$oid_cpqRackPowerSupplySerialNum . '.' . $_};
        my $psu_part = $result->{$oid_cpqRackPowerSupplyPartNumber . '.' . $_};
        my $psu_spare = $result->{$oid_cpqRackPowerSupplySparePartNumber . '.' . $_};
        my $psu_inputlinestatus = $result->{$oid_cpqRackPowerSupplyInputLineStatus . '.' . $_};
        my $psu_condition = $result->{$oid_cpqRackPowerSupplyCondition . '.' . $_};
        my $psu_pwrout = $result->{$oid_cpqRackPowerSupplyCurPwrOutput . '.' . $_};
        my $psu_intemp = $result->{$oid_cpqRackPowerSupplyIntakeTemp . '.' . $_};
        my $psu_exhtemp = $result->{$oid_cpqRackPowerSupplyExhaustTemp . '.' . $_};
        
        next if ($self->check_exclude(section => 'psu', instance => $psu_index));
        
        $total_watts += $psu_pwrout;
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("PSU %d status is %s [serial: %s, part: %s, spare: %s] (input line status %s) (status %s).",
                                    $psu_index, $map_conditions{$psu_condition},
                                    $psu_serial, $psu_part, $psu_spare,
                                    $inputline_status_map{$psu_inputlinestatus},
                                    $psu_status_map{$psu_status}
                                    ));
        
        my $exit = $self->get_severity(section => 'psu', value => $map_conditions{$psu_condition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("PSU %d status is %s",
                                           $psu_index, $map_conditions{$psu_condition}));
        }
        
        $self->{output}->perfdata_add(label => "psu_" . $psu_index . "_power", unit => 'W',
                                      value => $psu_pwrout);
        if (defined($psu_intemp) && $psu_intemp != -1) {
            $self->{output}->perfdata_add(label => "psu_" . $psu_index . "_temp_intake", unit => 'C',
                                          value => $psu_intemp);
        }
        if (defined($psu_exhtemp) && $psu_exhtemp != -1) {
            $self->{output}->perfdata_add(label => "psu_" . $psu_index . "_temp_exhaust", unit => 'C',
                                          value => $psu_exhtemp);
        }
    }
    
    $self->{output}->perfdata_add(label => "total_power", unit => 'W',
                                  value => $total_watts);
}

1;