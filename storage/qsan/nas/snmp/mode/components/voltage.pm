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

package storage::qsan::nas::snmp::mode::components::voltage;

use strict;
use warnings;
use storage::qsan::nas::snmp::mode::components::resources qw($mapping);

sub load {
    my ($self) = @_;
    
    if ($self->{monitor_loaded} == 0) {
        storage::qsan::nas::snmp::mode::components::resources::load_monitor(request => $self->{request});
        $self->{monitor_loaded} = 1;
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results_monitor}})) {
        next if ($oid !~ /^$mapping->{ems_type}->{oid}\.(.*)$/);
        my $instance = $1;
        next if ($self->{results_monitor}->{$oid} !~ /Voltage/i);

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results_monitor}, instance => $instance);        
        next if ($self->check_filter(section => 'voltage', instance => $instance));

        #+0.99 V (min = +0.75 V, max = +1.35 V)
        my $value = '-';
        $value = sprintf("%.2f", $1) if (defined($result->{ems_value}) && $result->{ems_value} =~ /^(\S+)\s+V/);
        
        $self->{components}->{voltage}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("voltage '%s' status is '%s' [instance = %s, value = %s]",
                                                        $result->{ems_item}, $result->{ems_status}, $instance, $value));
        $exit = $self->get_severity(label => 'monitor', section => 'voltage', value => $result->{ems_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("voltage '%s' status is '%s'", $result->{ems_item}, $result->{ems_status}));
        }
        
        next if ($value !~ /[0-9]/);
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $value);            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("voltage '%s' is '%s' V", $result->{ems_item}, $value));
        }
        $self->{output}->perfdata_add(label => 'voltage_' . $result->{ems_item} . '_' . $instance, unit => 'V', 
                                      value => $value,
                                      warning => $warn,
                                      critical => $crit
                                      );
    }
}

1;
