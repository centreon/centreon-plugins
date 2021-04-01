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

package apps::lmsensors::snmp::mode::components::misc;

use strict;
use warnings;

my $mapping = {
    lmMiscSensorsDevice => { oid => '.1.3.6.1.4.1.2021.13.16.5.1.2' },
    lmMiscSensorsValue  => { oid => '.1.3.6.1.4.1.2021.13.16.5.1.3' },
};

my $oid_lmMiscSensorsEntry = '.1.3.6.1.4.1.2021.13.16.5.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_lmMiscSensorsEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking misc");
    $self->{components}->{misc} = {name => 'misc', total => 0, skip => 0};
    return if ($self->check_filter(section => 'misc'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_lmMiscSensorsEntry}})) {
        next if ($oid !~ /^$mapping->{lmMiscSensorsValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_lmMiscSensorsEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'misc', instance => $instance, name => $result->{lmMiscSensorsDevice}));
        $self->{components}->{misc}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("misc '%s' values is %s [instance = %s]",
                                    $result->{lmMiscSensorsDevice}, $result->{lmMiscSensorsValue}, $instance, 
                                    ));
             
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'misc', instance => $instance, name => $result->{lmMiscSensorsDevice}, value => $result->{lmMiscSensorsValue});
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Misc '%s' value is %s", $result->{lmMiscSensorsDevice}, $result->{lmMiscSensorsValue}));
        }
        $self->{output}->perfdata_add(
            label => 'misc',, 
            nlabel => 'sensor.misc.current',
            instances => $result->{lmMiscSensorsDevice},
            value => $result->{lmMiscSensorsValue},
            warning => $warn,
            critical => $crit,
            min => 0,
        );
    }
}

1;
