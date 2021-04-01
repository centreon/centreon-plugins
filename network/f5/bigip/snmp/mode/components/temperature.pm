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

package network::f5::bigip::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    sysChassisTempTemperature => { oid => '.1.3.6.1.4.1.3375.2.1.3.2.3.2.1.2' },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{sysChassisTempTemperature}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{sysChassisTempTemperature}->{oid}}})) {
        $oid =~ /^$mapping->{sysChassisTempTemperature}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{sysChassisTempTemperature}->{oid}}, instance => $instance);
    
        next if ($self->check_filter(section => 'temperature', instance => $instance));
	
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' is %.2f C [instance: %s].", 
                                    $instance, $result->{sysChassisTempTemperature}, $instance
                                    ));
                                    
        if (defined($result->{sysChassisTempTemperature}) && $result->{sysChassisTempTemperature} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{sysChassisTempTemperature});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %.2f C", $instance, $result->{sysChassisTempTemperature}));
            }
            $self->{output}->perfdata_add(
                label => "temp", unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $instance,
                value => sprintf("%.2f", $result->{sysChassisTempTemperature}),
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
