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

package storage::qsan::nas::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    ems_type    => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.2' },
    ems_item    => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.3' },
    ems_value   => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.4' },
    ems_status  => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.5' },
};
my $oid_monitorEntry = '.1.3.6.1.4.1.22274.2.3.2.1';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_monitorEntry}})) {
        next if ($oid !~ /^$mapping->{ems_type}->{oid}\.(.*)$/);
        my $instance = $1;
        next if ($self->{results}->{$oid_monitorEntry}->{$oid} !~ /Temperature/i);
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_monitorEntry}, instance => $instance);
        next if ($self->check_filter(section => 'temperature', instance => $instance));

        # +72.0 (C) (hyst =  +5.0 (C), high = +90.0 (C))
        my $value = '-';
        $value = sprintf("%.2f", $1) if (defined($result->{ems_value}) && $result->{ems_value} =~ /^(\S+)\s+\(C\)/);
        
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s, value = %s]",
                                                        $result->{ems_item}, $result->{ems_status}, $instance, $value));
        $exit = $self->get_severity(label => 'monitor', section => 'temperature', value => $result->{ems_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{ems_item}, $result->{ems_status}));
        }
        
        next if ($value !~ /[0-9]/);
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $value);            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is '%s' C", $result->{ems_item}, $value));
        }
        $self->{output}->perfdata_add(label => 'temperature_' . $result->{ems_item} . '_' . $instance, unit => 'C', 
                                      value => $value,
                                      warning => $warn,
                                      critical => $crit
                                      );
    }
}

1;