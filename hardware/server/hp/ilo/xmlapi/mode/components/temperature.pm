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

package hardware::server::hp::ilo::xmlapi::mode::components::temperature;

use strict;
use warnings;

my %map_unit = (
    'celsius' => 'C',
);

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{TEMPERATURE}->{TEMP}));

    #<TEMPERATURE>
    #   <TEMP>
    #      <LABEL VALUE = "Temp 1"/>
    #      <LOCATION VALUE = "Ambient"/>
    #      <STATUS VALUE = "Ok"/>
    #      <CURRENTREADING VALUE = "20" UNIT="Celsius"/>
    #      <CAUTION VALUE = "42" UNIT="Celsius"/>
    #      <CRITICAL VALUE = "46" UNIT="Celsius"/>
    #   </TEMP>
    foreach my $result (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{TEMPERATURE}->{TEMP}}) {
        my $instance = $result->{LABEL}->{VALUE};
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                 $self->absent_problem(section => 'temperature', instance => $instance));

        $self->{components}->{temperature}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [location = %s] [value = %s]",
                                    $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}, $instance, $result->{LOCATION}->{VALUE},
                                    $result->{CURRENTREADING}->{VALUE}));
        
        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{STATUS}->{VALUE});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}));
        }
        
        next if ($result->{CURRENTREADING}->{VALUE} !~ /[0-9]/);
        my $unit = $map_unit{lc($result->{CURRENTREADING}->{UNIT})};
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{CURRENTREADING}->{VALUE});        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Temperature '%s' is %s %s", $result->{LABEL}->{VALUE}, $result->{CURRENTREADING}->{VALUE}, $unit));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => $unit,
            nlabel => 'hardware.temperature.' . lc($result->{CURRENTREADING}->{UNIT}),
            instances => $instance,
            value => $result->{CURRENTREADING}->{VALUE},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
