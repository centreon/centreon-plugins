#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Author : ArnoMLT
#

package storage::netgear::readynas::snmp::mode::components::temperature;

use strict;
use warnings;

my ($mapping, $oid_temperatureTable);

my $mapping_v6 = {
    temperatureValue => { oid => '.1.3.6.1.4.1.4526.22.5.1.2' },
	temperatureType => { oid => '.1.3.6.1.4.1.4526.22.5.1.3' },
    temperatureMax => { oid => '.1.3.6.1.4.1.4526.22.5.1.5' },
};
my $oid_temperatureTable_v6 = '.1.3.6.1.4.1.4526.22.5';

my $mapping_v4 = {
    temperatureValue => { oid => '.1.3.6.1.4.1.4526.18.5.1.2' },
	temperatureStatus => { oid => '.1.3.6.1.4.1.4526.18.5.1.3' },
};
my $oid_temperatureTable_v4 = '.1.3.6.1.4.1.4526.18.5';

sub load {
    my ($self) = @_;
    
	$mapping = $self->{mib_ver} == 4 ? $mapping_v4 : $mapping_v6;
	$oid_temperatureTable = $self->{mib_ver} == 4 ? $oid_temperatureTable_v4 : $oid_temperatureTable_v6;
	
    push @{$self->{request}}, { oid => $oid_temperatureTable };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_temperatureTable}})) {
        next if ($oid !~ /^$mapping->{temperatureValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_temperatureTable}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;
		
		my $temperatureMax_string = defined($result->{temperatureMax}) && $result->{temperatureMax} != -1 ? "  ($result->{temperatureMax} max)" : '';
		my $temperatureMax_unit = defined($result->{temperatureMax}) && $self->{mib_ver} == 6 ? 'C' : 'F';
	
		if ($self->{mib_ver} == 6){
			$self->{output}->output_add(long_msg => sprintf("'%s' %s temperature is %d%s%s.", 
										$instance, $result->{temperatureType}, $result->{temperatureValue},
										$temperatureMax_unit, $temperatureMax_string));
        
			if (defined($result->{temperatureValue}) && $result->{temperatureValue} != -1) {
				my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureValue});
				if ($checked == 0) {
					my $crit_th = $result->{temperatureMax} != -1 ? $result->{temperatureMax} : '';
					my $warn_th = $crit_th ne '' ? $crit_th-10 : '';
					$self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
					$self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
					$warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
					$crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
				}
				if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
					$self->{output}->output_add(severity => $exit,
												short_msg => sprintf("Temperature '%s' %s is %s degree %s",
												$instance, $result->{temperatureType}, $result->{temperatureValue}, $temperatureMax_unit));
				}
				$self->{output}->perfdata_add(label => "temp_" . $instance . "_" . $result->{temperatureType}, unit => $temperatureMax_unit,
											  value => $result->{temperatureValue},
											  warning => $warn,
											  critical => $crit);
			}
		}elsif ($self->{mib_ver} == 4){
			$self->{output}->output_add(long_msg => sprintf("temperature '%s' (%dF) is %s.", 
										$instance, $result->{temperatureValue}, $result->{temperatureStatus}));
								
			# check for warnings or criticals ?
			my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureValue});
			if ($checked == 1) {
				$self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn);
				$self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit);
				if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
					$self->{output}->output_add(severity => $exit,
												short_msg => sprintf("Temperature '%s' (%s%s) is %s.", $instance, $result->{temperatureValue}, $temperatureMax_unit, $exit));
				}
			}else{
								
				my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{temperatureStatus});
				if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
					$self->{output}->output_add(severity => $exit,
												short_msg => sprintf("Temperature '%s' (%s%s) is %s.", $instance, $result->{temperatureValue}, $temperatureMax_unit, $result->{temperatureStatus}));
				}
			}
			$self->{output}->perfdata_add(label => "temp_" . $instance, unit => $temperatureMax_unit,
											  value => $result->{temperatureValue});
		}
    }
}

1;