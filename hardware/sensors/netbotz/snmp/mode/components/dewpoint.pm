#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::sensors::netbotz::snmp::mode::components::dewpoint;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw(%map_status);

my $mapping = {
    dewPointSensorId            => { oid => '.1.3.6.1.4.1.5528.100.4.1.3.1.1' },
    dewPointSensorValue         => { oid => '.1.3.6.1.4.1.5528.100.4.1.3.1.2' },
    dewPointSensorErrorStatus   => { oid => '.1.3.6.1.4.1.5528.100.4.1.3.1.3', map => \%map_status },
    dewPointSensorLabel         => { oid => '.1.3.6.1.4.1.5528.100.4.1.3.1.4' },
};

my $oid_dewPointSensorEntry = '.1.3.6.1.4.1.5528.100.4.1.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_dewPointSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking dew points");
    $self->{components}->{dewpoint} = {name => 'dew points', total => 0, skip => 0};
    return if ($self->check_filter(section => 'dewpoint'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_dewPointSensorEntry}})) {
        next if ($oid !~ /^$mapping->{dewPointSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_dewPointSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'dewpoint', instance => $instance));
        $self->{components}->{dewpoint}->{total}++;
        
        $result->{dewPointSensorValue} *= 0.1;
        my $label = defined($result->{dewPointSensorLabel}) && $result->{dewPointSensorLabel} ne '' ? $result->{dewPointSensorLabel} : $result->{dewPointSensorId};
        $self->{output}->output_add(long_msg => sprintf("dew point '%s' status is '%s' [instance = %s] [value = %s]",
                                    $label, $result->{dewPointSensorErrorStatus}, $instance, 
                                    $result->{dewPointSensorValue}));
        
        my $exit = $self->get_severity(label => 'default', section => 'dewpoint', value => $result->{dewPointSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Dew point '%s' status is '%s'", $label, $result->{dewPointSensorErrorStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'dewpoint', instance => $instance, value => $result->{dewPointSensorValue});
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Dew point '%s' is %s C", $label, $result->{dewPointSensorValue}));
        }
        $self->{output}->perfdata_add(label => 'dewpoint_' . $label, unit => 'C', 
                                      value => $result->{dewPointSensorValue},
                                      warning => $warn,
                                      critical => $crit,
                                      );
    }
}

1;