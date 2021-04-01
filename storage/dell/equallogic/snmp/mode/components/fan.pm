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

package storage::dell::equallogic::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (
    0 => 'unknown', 
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical',
);

# In MIB 'eqlcontroller.mib'
my $mapping = {
    eqlMemberHealthDetailsFanName => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.2' },
    eqlMemberHealthDetailsFanValue => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.3' },
    eqlMemberHealthDetailsFanCurrentState => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.4', map => \%map_fan_status },
    eqlMemberHealthDetailsFanHighCriticalThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.5' },
    eqlMemberHealthDetailsFanHighWarningThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.6' },
    eqlMemberHealthDetailsFanLowCriticalThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.7' },
    eqlMemberHealthDetailsFanLowWarningThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.8' },
};
my $oid_eqlMemberHealthDetailsFanEntry = '.1.3.6.1.4.1.12740.2.1.7.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_eqlMemberHealthDetailsFanEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqlMemberHealthDetailsFanEntry}})) {
        next if ($oid !~ /^$mapping->{eqlMemberHealthDetailsFanCurrentState}->{oid}\.(\d+\.\d+)\.(.*)$/);
        my ($member_instance, $instance) = ($1, $2);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlMemberHealthDetailsFanEntry}, instance => $member_instance . '.' . $instance);

        next if ($self->check_filter(section => 'fan', instance => $member_instance . '.' . $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Fan '%s/%s' status is %s [instance: %s].",
                                    $member_name, $result->{eqlMemberHealthDetailsFanName}, $result->{eqlMemberHealthDetailsFanCurrentState},
                                    $member_instance . '.' . $instance
                                    ));
        my $exit = $self->get_severity(section => 'fan', value => $result->{eqlMemberHealthDetailsFanCurrentState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Fan '%s/%s' status is %s",
                                                             $member_name, $result->{eqlMemberHealthDetailsFanName}, $result->{eqlMemberHealthDetailsFanCurrentState}));
        }
        
        if (defined($result->{eqlMemberHealthDetailsFanValue})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{eqlMemberHealthDetailsFanValue});
            if ($checked == 0) {
                my $warn_th = $result->{eqlMemberHealthDetailsFanLowWarningThreshold} . ':' . $result->{eqlMemberHealthDetailsFanHighWarningThreshold};
                my $crit_th = $result->{eqlMemberHealthDetailsFanLowCriticalThreshold} . ':' . $result->{eqlMemberHealthDetailsFanHighCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-fan-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-fan-instance-' . $instance, value => $crit_th);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-fan-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-fan-instance-' . $instance);
            }
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Fan '%s/%s' speed is %s rpm", $member_name, $result->{eqlMemberHealthDetailsFanName}, $result->{eqlMemberHealthDetailsFanValue}));
            }
            $self->{output}->perfdata_add(
                label => "fan", unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => [$member_name, $instance],
                value => $result->{eqlMemberHealthDetailsFanValue},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
