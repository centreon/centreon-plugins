#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));

    my $oid_sysChassisTempEntry = '.1.3.6.1.4.1.3375.2.1.3.2.3.2.1';
    my $oid_sysChassisTempTemperature = '.1.3.6.1.4.1.3375.2.1.3.2.3.2.1.2';
   
    my $result = $self->{snmp}->get_table(oid => $oid_sysChassisTempEntry);
    return if (scalar(keys %$result) <= 0); 

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_sysChassisTempTemperature\.(\d+)$/);
        my $instance = $1;
        next if ($self->check_exclude(section => 'temperature', instance => $instance));
	
        my $exit_code = $self->{perfdata}->threshold_check(value => $result->{$oid_sysChassisTempTemperature . '.' . $instance},
                                                           threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    	$self->{components}->{temperature}->{total}++;
    	$self->{output}->output_add(severity => $exit_code,long_msg => sprintf("temp_" . $instance . " is %.2f C", $result->{$oid_sysChassisTempTemperature . '.' . $instance}));
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,short_msg => sprintf("temp_" . $instance . " is %.2f C", $result->{$oid_sysChassisTempTemperature . '.' . $instance}));
        }

    	$self->{output}->perfdata_add(label => "temp_" . $instance , unit => 'C', 
                                      value => sprintf("%.2f", $result->{$oid_sysChassisTempTemperature . '.' . $instance}),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    }
}

1;
