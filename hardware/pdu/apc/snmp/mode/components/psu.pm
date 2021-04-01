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

package hardware::pdu::apc::snmp::mode::components::psu;

use strict;
use warnings;

my %map_status = (
    1 => 'ok',
    2 => 'failed',
    3 => 'notPresent',
);

# In MIB 'PowerNet-MIB'
my $mapping = {
    rPDUPowerSupply1Status => { oid => '.1.3.6.1.4.1.318.1.1.12.4.1.1', map => \%map_status },
    rPDUPowerSupply2Status => { oid => '.1.3.6.1.4.1.318.1.1.12.4.1.2', map => \%map_status },
};
my $oid_rPDUPowerSupplyDevice = '.1.3.6.1.4.1.318.1.1.12.4.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rPDUPowerSupplyDevice };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    return if (!defined($self->{results}->{$oid_rPDUPowerSupplyDevice}));
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rPDUPowerSupplyDevice}, instance => '0');
    for (my $i = 1; $i <= 2; $i++) {
        next if (!defined($result->{'rPDUPowerSupply' . $i . 'Status'}));
        next if ($result->{'rPDUPowerSupply' . $i . 'Status'} !~ /notPresent/i && 
                 $self->absent_problem(section => 'psu', instance => $i));
        next if ($self->check_filter(section => 'psu', instance => $i));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s' [instance: %s]", 
                                    $i, $result->{'rPDUPowerSupply' . $i . 'Status'}, 
                                    $i));
        my $exit = $self->get_severity(section => 'psu', instance => $i, value => $result->{'rPDUPowerSupply' . $i . 'Status'});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", 
                                                             $i, $result->{'rPDUPowerSupply' . $i . 'Status'}));
        }
    }
}

1;
