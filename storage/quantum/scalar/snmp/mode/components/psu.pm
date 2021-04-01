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

package storage::quantum::scalar::snmp::mode::components::psu;

use strict;
use warnings;

my $map_psu_status = {
    0 => 'unknown', 1 => 'good', 2 => 'failed', 3 => 'missing'
};

# In MIB 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'
my $mapping = {
    libraryPSName               => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.100.2.1.2' },
    libraryPSLocation           => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.100.2.1.3' },
    libraryPSStatus             => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.100.2.1.6', map => $map_psu_status },
    libraryPSPowerConsumption   => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.100.2.1.7' },
};
my $oid_libraryPowerSupplyEntry = '.1.3.6.1.4.1.3697.1.10.15.5.100.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_libraryPowerSupplyEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_libraryPowerSupplyEntry}})) {
        next if ($oid !~ /^$mapping->{libraryPSStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_libraryPowerSupplyEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s] [power consumption = %s]",
                                    $result->{libraryPSLocation}, $result->{libraryPSStatus}, $instance, 
                                    $result->{libraryPSPowerConsumption}));
        
        $exit = $self->get_severity(section => 'psu', instance => $instance, value => $result->{libraryPSStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $result->{libraryPSLocation}, $result->{libraryPSStatus}));
        }

        next if (!defined($result->{libraryPSPowerConsumption}) || $result->{libraryPSPowerConsumption} !~ /[0-9]/);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'power', instance => $instance, value => $result->{libraryPSPowerConsumption});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Power supply consumption '%s' is %s W", $result->{libraryPSLocation}, $result->{libraryPSPowerConsumption})
            );
        }
        
        $self->{output}->perfdata_add(
            nlabel => 'hardware.psu.power.watt', unit => 'W',
            instances => $result->{libraryPSLocation},
            value => $result->{libraryPSPowerConsumption},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
