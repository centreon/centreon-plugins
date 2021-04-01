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

package storage::hp::lefthand::snmp::mode::components::fan;

use strict;
use warnings;
use storage::hp::lefthand::snmp::mode::components::resources qw($map_status);

my $mapping = {
    infoFanName     => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.111.1.2' },
    infoFanSpeed    => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.111.1.3' }, # not defined
    infoFanMinSpeed => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.111.1.4' }, # not defined
    infoFanState    => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.111.1.90' },
    infoFanStatus   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.111.1.91', map => $map_status },
};
my $oid_infoFanEntry = '.1.3.6.1.4.1.9804.3.1.1.2.1.111.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_infoFanEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_infoFanEntry}})) {
        next if ($oid !~ /^$mapping->{infoFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_infoFanEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s, state = %s, speed = %s]",
                                    $result->{infoFanName}, $result->{infoFanStatus}, $instance, $result->{infoFanState},
                                    defined($result->{infoFanSpeed}) ? $result->{infoFanSpeed} : '-'));
        
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{infoFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' state is '%s'", $result->{infoFanName}, $result->{infoFanState}));
        }        
        
        next if (!defined($result->{infoFanSpeed}) || $result->{infoFanSpeed} !~ /[0-9]/);
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{infoFanSpeed});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = defined($result->{infoFanMinSpeed}) ? $result->{infoFanMinSpeed} . ':' : '';
            $self->{perfdata}->threshold_validate(label => 'warning-fan-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-fan-instance-' . $instance, value => $crit_th);
            
            $exit = $self->{perfdata}->threshold_check(
                value => $result->{infoFanSpeed}, 
                threshold => [ { label => 'critical-fan-instance-' . $instance, exit_litteral => 'critical' }, 
                               { label => 'warning-fan-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-fan-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-fan-instance-' . $instance)
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("fan '%s' speed is %s rpm", $result->{infoFanName}, $result->{infoFanSpeed}));
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $result->{infoFanName},
            value => $result->{infoFanSpeed},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
