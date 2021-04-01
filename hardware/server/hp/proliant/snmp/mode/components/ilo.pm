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

package hardware::server::hp::proliant::snmp::mode::components::ilo;

use strict;
use warnings;

my %map_status = (
    1 => 'unknown',
    2 => 'ok',
    3 => 'degraded',
    4 => 'failed',
);
my %map_bitmask_status = (
    16 => 'I2C error',
    15 => 'EEPROM error',
    14 => 'SRAM error',
    13 => 'CPLD error',
    12 => 'Mouse interface error',
    11 => 'NIC Error',
    10 => 'PCMCIA Error',
    9 => 'Video Error',
    8 => 'NVRAM write/read/verify error',
    7 => 'NVRAM interface error',
    6 => 'Battery interface error',
    5 => 'Keyboard interface error',
    4 => 'Serial port UART error',
    3 => 'Modem UART error',
    2 => 'Modem firmware error',
    1 => 'Memory test error',
    0 => 'Busmaster I/O read error',
);

# In MIB 'CPQSM2-MIB.mib'
my $mapping = {
    cpqSm2MibCondition  => { oid => '.1.3.6.1.4.1.232.9.1.3', map => \%map_status },
};
my $oid_cpqSm2CntlrSelfTestErrors = '.1.3.6.1.4.1.232.9.2.2.9';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{cpqSm2MibCondition}->{oid} }, { oid => $oid_cpqSm2CntlrSelfTestErrors };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ilo");
    $self->{components}->{ilo} = {name => 'ilo', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ilo'));

    return if (scalar(keys %{$self->{results}->{$mapping->{cpqSm2MibCondition}->{oid}}}) == 0);
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{cpqSm2MibCondition}->{oid}}, instance => '0');

    next if ($self->check_filter(section => 'ilo', instance => '0'));
    $self->{components}->{ilo}->{total}++;

    my @message_error = ();
    if (defined($self->{results}->{$oid_cpqSm2CntlrSelfTestErrors}->{$oid_cpqSm2CntlrSelfTestErrors . '.0'})) {
        foreach my $bit (keys %map_bitmask_status) {
            if (int($self->{results}->{$oid_cpqSm2CntlrSelfTestErrors}->{$oid_cpqSm2CntlrSelfTestErrors . '.0'}) & (1 << ($bit))) {
                push @message_error, $map_bitmask_status{$bit};
            }
        }
    }
    
    $self->{output}->output_add(long_msg => sprintf("ilo status is %s [message = %s].", 
                                $result->{cpqSm2MibCondition}, join(', ', @message_error)));
    my $exit = $self->get_severity(label => 'default', section => 'ilo', value => $result->{cpqSm2MibCondition});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("ilo is %s", 
                                        $result->{cpqSm2MibCondition}));
    }
}

1;