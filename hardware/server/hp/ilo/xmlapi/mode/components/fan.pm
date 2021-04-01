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

package hardware::server::hp::ilo::xmlapi::mode::components::fan;

use strict;
use warnings;

my %map_speed_unit = (
    'percentage' => '%',
);

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{FANS}->{FAN}));
    
    # <FANS>
    #    <FAN>
    #        <LABEL VALUE = "Fan Block 1"/>
    #        <ZONE VALUE = "System"/>
    #        <STATUS VALUE = "Ok"/>
    #        <SPEED VALUE = "35" UNIT="Percentage"/>
    #    </FAN>
    #
    foreach my $result (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{FANS}->{FAN}}) {
        my $instance = $result->{LABEL}->{VALUE};
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                 $self->absent_problem(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}, $instance, 
                                    $result->{SPEED}->{VALUE}));
        
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{STATUS}->{VALUE});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}));
        }
        
        next if ($result->{SPEED}->{VALUE} !~ /[0-9]/);
        my $unit = $map_speed_unit{lc($result->{SPEED}->{UNIT})};
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{SPEED}->{VALUE});        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Fan '%s' is %s %s", $result->{LABEL}->{VALUE}, $result->{SPEED}->{VALUE}, $unit));
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => $unit,
            nlabel => 'hardware.fan.speed.' . lc($result->{SPEED}->{UNIT}),
            instances => $instance,
            value => $result->{SPEED}->{VALUE},
            warning => $warn,
            critical => $crit, 
            min => 0
        );
    }
}

1;
