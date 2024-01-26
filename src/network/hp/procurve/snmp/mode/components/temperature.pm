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

package network::hp::procurve::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    name      => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.8.1.1.2' }, # hpSystemAirName
    value     => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.8.1.1.3' }, # hpSystemAirCurrentTemp
    threshold => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.8.1.1.7' }  # hpSystemAirThresholdTemp
};
my $oid_airTempTable = '.1.3.6.1.4.1.11.2.14.11.1.2.8.1'; # hpSystemAirTempTable

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { 
        oid => $oid_airTempTable,
        start => $mapping->{name}->{oid},
        end => $mapping->{threshold}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_airTempTable }})) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $oid_airTempTable }, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));

        next if ($result->{value} !~ /^(\d+)C/i);
        my $value = $1;

        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' is '%s' celsius [instance: %s]",
                $result->{name}, $value, $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $value);            
        if ($checked == 0 && $result->{threshold} =~ /^(\d+)C/i) {
            my $crit_th = $1;
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);

            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "temperature '%s' is '%s' celsius", $result->{name}, $value
                )
            );
        }
    
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => $result->{name},
            value => $value,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
