#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::qnap::snmp::mode::components::disk;

use strict;
use warnings;

my %map_status_disk = (
    0 => 'ready',
    '-5' => 'noDisk',
    '-6' => 'invalid',
    '-9' => 'rwError',
    '-4' => 'unknown',
);

# In MIB 'NAS.mib'
my $mapping = {
    HdDescr => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.2' },
    HdTemperature => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.3' },
    HdStatus => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.4', map => \%map_status_disk },
};
my $mapping2 = {
    HdSmartInfo => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.7' },
};
my $oid_HdEntry = '.1.3.6.1.4.1.24681.1.2.11.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_HdEntry, start => $mapping->{HdDescr}->{oid}, end => $mapping->{HdStatus}->{oid} };
    push @{$options{request}}, { oid => $mapping2->{HdSmartInfo}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_HdEntry}})) {
        next if ($oid !~ /^$mapping->{HdDescr}->{oid}\.(\d+)$/);
        my $instance = $1;
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_HdEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping2->{HdSmartInfo}->{oid} }, instance => $instance);

        next if ($self->check_exclude(section => 'disk', instance => $instance));
        next if ($result->{HdStatus} eq 'noDisk' && 
                 $self->absent_problem(section => 'disk', instance => $instance));
        
        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Disk '%s' [instance: %s, temperature: %s, smart status: %s] status is %s.",
                                    $result->{HdDescr}, $instance, $result->{HdTemperature}, $result2->{HdSmartInfo}, $result->{HdStatus}));
        my $exit = $self->get_severity(section => 'disk', value => $result->{HdStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is %s.", $result->{HdDescr}, $result->{HdStatus}));
        }
        
        $exit = $self->get_severity(section => 'smartdisk', value => $result2->{HdSmartInfo});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' smart status is %s.", $result->{HdDescr}, $result2->{HdSmartInfo}));
        }
        
        if ($result->{HdTemperature} =~ /([0-9]+)\s*C/) {
            my $disk_temp = $1;
            my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'disk', instance => $instance, value => $disk_temp);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Disk '%s' temperature is %s degree centigrade", $result->{HdDescr}, $disk_temp));
            }
            $self->{output}->perfdata_add(label => 'temp_disk_' . $instance, unit => 'C',
                                          value => $disk_temp
                                          );
        }
    }
}

1;