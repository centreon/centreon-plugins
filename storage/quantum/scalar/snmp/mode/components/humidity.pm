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

package storage::quantum::scalar::snmp::mode::components::humidity;

use strict;
use warnings;
use storage::quantum::scalar::snmp::mode::components::resources qw($map_sensor_status);

# In MIB 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'
my $mapping = {
    libraryHumiditySensorName     => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.2' },
    libraryHumiditySensorLocation => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.3' },
    libraryHumiditySensorStatus   => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.4', map => $map_sensor_status },
    libraryHumiditySensorValue    => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1.5' },
};
my $oid_libraryHumiditySensorEntry = '.1.3.6.1.4.1.3697.1.10.15.5.120.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_libraryHumiditySensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking humidities");
    $self->{components}->{humidity} = {name => 'humidity', total => 0, skip => 0};
    return if ($self->check_filter(section => 'humidity'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_libraryHumiditySensorEntry}})) {
        next if ($oid !~ /^$mapping->{libraryHumiditySensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_libraryHumiditySensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'humidity', instance => $instance));
        $self->{components}->{humidity}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("humidity '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{libraryHumiditySensorLocation}, $result->{libraryHumiditySensorStatus}, $instance, 
                                    $result->{libraryHumiditySensorValue}));
        
        $exit = $self->get_severity(label => 'default', section => 'humidity', instance => $instance, value => $result->{libraryHumiditySensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Humidity '%s' status is '%s'", $result->{libraryHumiditySensorLocation}, $result->{libraryHumiditySensorStatus}));
        }

        next if (!defined($result->{libraryHumiditySensorValue}) || $result->{libraryHumiditySensorValue} !~ /[0-9]/);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{libraryHumiditySensorValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Humdity '%s' is %s %%", $result->{libraryHumiditySensorLocation}, $result->{libraryHumiditySensorValue})
            );
        }
        
        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.humidity.percentage', unit => '%',
            instances => $result->{libraryHumiditySensorLocation},
            value => $result->{libraryHumiditySensorValue},
            warning => $warn,
            critical => $crit,
            min => 0, max => 100
        );
    }
}

1;
