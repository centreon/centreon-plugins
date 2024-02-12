#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::sensors::jacarta::snmp::mode::components::input;

use strict;
use warnings;
use hardware::sensors::jacarta::snmp::mode::components::resources qw(%map_input_status);

sub load {}

sub check_inSeptPro {
    my ($self) = @_;

    my $mapping = {
        name  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.3.1.2' }, # isDeviceMonitorDigitalInName
        alarm => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.3.1.4', map => \%map_input_status } # isDeviceMonitorDigitalInAlarm
    };
    my $oid_digitalEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.1.3.1';

    my $snmp_result = $self->{snmp}->get_table(oid => $oid_digitalEntry);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{alarm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        next if ($self->check_filter(section => 'input', instance => $instance));
        $self->{components}->{input}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "input '%s' status is '%s' [instance: %s]",
                $result->{name}, $result->{alarm}, $instance
            )
        );

        my $exit = $self->get_severity(section => 'input', value => $result->{alarm});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Input '%s' status is '%s'", $result->{name}, $result->{alarm})
            );
        }
    }
}

sub check {
    my ($self) = @_;

    return if ($self->{inSept} == 1);

    $self->{output}->output_add(long_msg => "Checking digital inputs");
    $self->{components}->{input} = { name => 'inputs', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'input'));

    check_inSeptPro($self) if ($self->{inSeptPro} == 1);
}

1;
