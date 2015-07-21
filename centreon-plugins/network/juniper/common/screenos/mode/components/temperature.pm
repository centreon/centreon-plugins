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

package network::juniper::common::screenos::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperatures} = {name => 'temperatures', total => 0};
    return if ($self->check_exclude('temperatures'));

    my $oid_nsTemperatureEntry = '.1.3.6.1.4.1.3224.21.4.1';
    my $oid_nsTemperatureCur = '.1.3.6.1.4.1.3224.21.4.1.3';
    my $oid_nsTemperatureDesc = '.1.3.6.1.4.1.3224.21.4.1.4';
   
    my $result = $self->{snmp}->get_table(oid => $oid_nsTemperatureEntry);
    return if (scalar(keys %$result) <= 0); 

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_nsTemperatureCur\.(\d+)$/);
        my $instance = $1;

        next if ($self->check_exclude(section => 'temperatures', instance => $instance));
	
	my $temperature_name = $result->{$oid_nsTemperatureDesc . '.' . $instance};

	my $exit_code = $self->{perfdata}->threshold_check(value => $result->{$oid_nsTemperatureCur . '.' . $instance},
            threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    	$self->{components}->{temperatures}->{total}++;

    	$self->{output}->output_add(severity => $exit_code,long_msg => sprintf($temperature_name . " is %.2f C", $result->{$oid_nsTemperatureCur . '.' . $instance}));

        if ($exit_code ne 'ok') {
            $self->{output}->output_add(severity => $exit_code,short_msg => sprintf($temperature_name . " is %.2f C", $result->{$oid_nsTemperatureCur . '.' . $instance}));
        }

	$temperature_name =~ s/\ /_/g;
    	$self->{output}->perfdata_add(label => $temperature_name , unit => 'C', value => sprintf("%.2f", $result->{$oid_nsTemperatureCur . '.' . $instance}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));    
        }
    }


1;
