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

package centreon::common::adic::tape::snmp::mode::components::fan;

use strict;
use warnings;

my %map_status = (
    1 => 'nominal', 
    2 => 'warningLow', 3 => 'warningHigh',
    4 => 'alarmLow', 5 => 'alarmHigh', 
    6 => 'notInstalled', 7 => 'noData',
);

my $mapping = {
    coolingFanName      => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.2' },
    coolingFanStatus    => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.3', map => \%map_status },
    coolingFanRPM       => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.4' },
    coolingFanWarningHi => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.8' },
    coolingFanNominalHi => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.6' },
    coolingFanNominalLo => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.5' },
    coolingFanWarningLo => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.7' },
    coolingFanLocation  => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.40.1.9' },
};
my $oid_coolingFanEntry = '.1.3.6.1.4.1.3764.1.1.200.200.40.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_coolingFanEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_coolingFanEntry}})) {
        next if ($oid !~ /^$mapping->{coolingFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_coolingFanEntry}, instance => $instance);
        
        $result->{coolingFanName} =~ s/\s+/ /g;
        $result->{coolingFanName} = centreon::plugins::misc::trim($result->{coolingFanName});
        $result->{coolingFanLocation} =~ s/,/_/g;
        my $id = $result->{coolingFanName} . '_' . $result->{coolingFanLocation};
        
        next if ($self->check_filter(section => 'fan', instance => $id));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s] [value = %s]",
                                    $id, $result->{coolingFanStatus}, $id, 
                                    $result->{coolingFanRPM}));
        
        my $exit = $self->get_severity(label => 'sensor', section => 'fan', value => $result->{coolingFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' status is '%s'", $id, $result->{coolingFanStatus}));
            next;
        }
     
        if (defined($result->{coolingFanRPM}) && $result->{coolingFanRPM} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{coolingFanRPM});
            if ($checked == 0) {
                $result->{coolingFanNominalLo} = (defined($result->{coolingFanNominalLo}) && $result->{coolingFanNominalLo} =~ /[0-9]/) ?
                    $result->{coolingFanNominalLo} : '';
                $result->{coolingFanWarningLo} = (defined($result->{coolingFanWarningLo}) && $result->{coolingFanWarningLo} =~ /[0-9]/) ?
                    $result->{coolingFanWarningLo} : '';
                $result->{coolingFanNominalHi} = (defined($result->{coolingFanNominalHi}) && $result->{coolingFanNominalHi} =~ /[0-9]/) ?
                    $result->{coolingFanNominalHi} : '';
                $result->{coolingFanWarningHi} = (defined($result->{coolingFanWarningHi}) && $result->{coolingFanWarningHi} =~ /[0-9]/) ?
                    $result->{coolingFanWarningHi} : '';
                my $warn_th = $result->{coolingFanNominalLo} . ':' . $result->{coolingFanNominalHi};
                my $crit_th = $result->{coolingFanWarningLo} . ':' . $result->{coolingFanWarningHi};
                $self->{perfdata}->threshold_validate(label => 'warning-fan-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-fan-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(value => $result->{coolingFanRPM}, threshold => [ { label => 'critical-fan-instance-' . $instance, exit_litteral => 'critical' }, 
                                                                                                             { label => 'warning-fan-instance-' . $instance, exit_litteral => 'warning' } ]);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-fan-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-fan-instance-' . $instance);
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan '%s' is %s rpm", $id, $result->{coolingFanRPM}));
            }
            $self->{output}->perfdata_add(
                label => 'fan', unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => $id,
                value => $result->{coolingFanRPM},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
