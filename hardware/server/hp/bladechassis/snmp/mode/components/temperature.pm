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

package hardware::server::hp::bladechassis::snmp::mode::components::temperature;

use strict;
use warnings;

my $map_conditions = {
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
};

my $map_temp_type = {
    1 => 'other',
    5 => 'blowout',
    9 => 'caution',
    15 => 'critical',
};

my $mapping = {
    temp_name       => { oid => '.1.3.6.1.4.1.232.22.2.3.1.2.1.4' }, # cpqRackCommonEnclosureTempSensorEnclosureName
    temp_location   => { oid => '.1.3.6.1.4.1.232.22.2.3.1.2.1.5' }, # cpqRackCommonEnclosureTempLocation
    temp_current    => { oid => '.1.3.6.1.4.1.232.22.2.3.1.2.1.6' }, # cpqRackCommonEnclosureTempCurrent
    temp_threshold  => { oid => '.1.3.6.1.4.1.232.22.2.3.1.2.1.7' }, # cpqRackCommonEnclosureTempThreshold
    temp_condition  => { oid => '.1.3.6.1.4.1.232.22.2.3.1.2.1.8', map => $map_conditions }, # cpqRackCommonEnclosureTempCondition
    temp_type       => { oid => '.1.3.6.1.4.1.232.22.2.3.1.2.1.9', map => $map_temp_type }, # cpqRackCommonEnclosureTempType
};

sub check {
    my ($self) = @_;

    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    $self->{output}->output_add(long_msg => "checking temperatures");
    return if ($self->check_filter(section => 'temperature'));
    
    my $oid_cpqRackCommonEnclosureTempSensorIndex = '.1.3.6.1.4.1.232.22.2.3.1.2.1.3';
    
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureTempSensorIndex);
    return if (scalar(keys %$snmp_result) <= 0);
    
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        $key =~ /^$oid_cpqRackCommonEnclosureTempSensorIndex\.(.*)$/;
        my $oid_end = $1;
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }

    $snmp_result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $temp_index = $_;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $temp_index);
        
		if ($result->{temp_current} == -1) {
			$self->{output}->output_add(long_msg => sprintf("skipping instance $temp_index: current -1"), debug => 1);
			next;
		}
        
        next if ($self->check_filter(section => 'temperature', instance => $temp_index));
		
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is %s [name: %s, location: %s] (value = %s, threshold = %s%s).",
                                    $temp_index, $result->{temp_condition},
                                    $result->{temp_name}, $result->{temp_location},
                                    $result->{temp_current}, $result->{temp_threshold},
                                    defined($result->{temp_type}) ? ", status type = " . $result->{temp_type} : ''));
        my $exit = $self->get_severity(label => 'default', section => 'temperature', instance => $temp_index, value => $result->{temp_condition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is %s",
                                          $temp_index, $result->{temp_condition}));
        }
        
        $self->{output}->perfdata_add(
            label => "temp", unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $temp_index,
            value => $result->{temp_current},
            warning => $result->{temp_threshold}
        );
    }
}

1;
