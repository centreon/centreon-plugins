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

package network::citrix::netscaler::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    0 => 'normal',
    1 => 'not present',
    2 => 'failed',
    3 => 'not supported',
);

my $mapping = {
    sysHealthCounterName    => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.7.1.1' },
    sysHealthCounterValue   => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.7.1.2', map => \%map_psu_status  },
};
my $oid_nsSysHealthEntry = '.1.3.6.1.4.1.5951.4.1.1.41.7.1';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_nsSysHealthEntry}})) {
        next if ($oid !~ /^$mapping->{sysHealthCounterName}->{oid}\.(.*)$/);
        my $instance = $1;
        next if ($self->{results}->{$oid_nsSysHealthEntry}->{$oid} !~ /PowerSupply(.)(?:Status|FailureStatus)/i);
        my $power_num = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_nsSysHealthEntry}, instance => $instance);
        
        next if ($result->{sysHealthCounterValue} eq 'not present' &&
                 $self->absent_problem(section => 'psu', instance => $power_num));
        next if ($self->check_filter(section => 'psu', instance => $instance));

        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s]",
                                                        $power_num, $result->{sysHealthCounterValue}, $power_num));
        $exit = $self->get_severity(section => 'psu', value => $result->{sysHealthCounterValue});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $power_num, $result->{sysHealthCounterValue}));
        }
    }
}

1;