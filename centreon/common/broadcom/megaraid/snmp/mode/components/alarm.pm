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

package centreon::common::broadcom::megaraid::snmp::mode::components::alarm;

use strict;
use warnings;

my %map_alarm_status = (
    1 => 'status-invalid', 2 => 'status-ok', 3 => 'status-critical', 4 => 'status-nonCritical', 
    5 => 'status-unrecoverable', 6 => 'status-not-installed', 7 => 'status-unknown', 8 => 'status-not-available'
);

my $mapping = {
    enclosureId_EAT => { oid => '.1.3.6.1.4.1.3582.4.1.5.7.1.2' },
    alarmStatus => { oid => '.1.3.6.1.4.1.3582.4.1.5.7.1.3', map => \%map_alarm_status },
};
my $oid_enclosureAlarmEntry= '.1.3.6.1.4.1.3582.4.1.5.7.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{requEAT}}, { oid => $oid_enclosureAlarmEntry, start => $mapping->{enclosureId_EAT}->{oid}, 
        end => $mapping->{alarmStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking alarms");
    $self->{components}->{alarm} = {name => 'alarms', total => 0, skip => 0};
    return if ($self->check_filter(section => 'alarm'));
    
    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_enclosureAlarmEntry}})) {
        next if ($oid !~ /^$mapping->{alarmStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclosureAlarmEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'alarm', instance => $instance));
        if ($result->{alarmStatus} =~ /status-not-installed/i) {
            $self->absent_problem(section => 'alarm', instance => $instance);
            next;
        }

        $self->{components}->{alarm}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Alarm '%s' status is '%s' [instance = %s, enclosure = %s]",
                                                        $instance, $result->{alarmStatus}, $instance, $result->{enclosureId_EAT}));
        $exit = $self->get_severity(label => 'default', section => 'alarm', value => $result->{alarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Alarm '%s' status is '%s'", $instance, $result->{alarmStatus}));
        }
    }
}

1;
