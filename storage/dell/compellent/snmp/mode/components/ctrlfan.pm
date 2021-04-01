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

package storage::dell::compellent::snmp::mode::components::ctrlfan;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scCtlrFanStatus     => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1.3', map => \%map_sc_status },
    scCtlrFanName       => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1.4' },
    scCtlrFanCurrentRpm => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1.5' },
    scCtlrFanWarnLwrRpm  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1.8' },
    scCtlrFanWarnUprRpm  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1.9' },
    scCtlrFanCritLwrRpm  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1.10' },
    scCtlrFanCritUprRpm  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1.11' },
};
my $oid_scCtlrFanEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.16.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scCtlrFanEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking controller fans");
    $self->{components}->{ctrlfan} = {name => 'controller fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ctrlfan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scCtlrFanEntry}})) {
        next if ($oid !~ /^$mapping->{scCtlrFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scCtlrFanEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'ctrlfan', instance => $instance));

        $self->{components}->{ctrlfan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("controller fan '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{scCtlrFanName}, $result->{scCtlrFanStatus}, $instance, 
                                    $result->{scCtlrFanCurrentRpm}));
        
        my $exit = $self->get_severity(label => 'default', section => 'ctrlfan', value => $result->{scCtlrFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Controller fan '%s' status is '%s'", $result->{scCtlrFanName}, $result->{scCtlrFanStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'ctrlfan', instance => $instance, value => $result->{scCtlrFanCurrentRpm});
        if ($checked == 0) {
            $result->{scCtlrFanWarnLwrRpm} = (defined($result->{scCtlrFanWarnLwrRpm}) && $result->{scCtlrFanWarnLwrRpm} =~ /[0-9]/) ?
                $result->{scCtlrFanWarnLwrRpm} : '';
            $result->{scCtlrFanCritLwrRpm} = (defined($result->{scCtlrFanCritLwrRpm}) && $result->{scCtlrFanCritLwrRpm} =~ /[0-9]/) ?
                $result->{scCtlrFanCritLwrRpm} : '';
            $result->{scCtlrFanWarnUprRpm} = (defined($result->{scCtlrFanWarnUprRpm}) && $result->{scCtlrFanWarnUprRpm} =~ /[0-9]/) ?
                $result->{scCtlrFanWarnUprRpm} : '';
            $result->{scCtlrFanCritUprRpm} = (defined($result->{scCtlrFanCritUprRpm}) && $result->{scCtlrFanCritUprRpm} =~ /[0-9]/) ?
                $result->{scCtlrFanCritUprRpm} : '';
            my $warn_th = $result->{scCtlrFanWarnLwrRpm} . ':' . $result->{scCtlrFanWarnUprRpm};
            my $crit_th = $result->{scCtlrFanCritLwrRpm} . ':' . $result->{scCtlrFanCritUprRpm};
            $self->{perfdata}->threshold_validate(label => 'warning-ctrlfan-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-ctrlfan-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-ctrlfan-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-ctrlfan-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Controller fan '%s' is %s rpm", $result->{scCtlrFanName}, $result->{scCtlrFanCurrentRpm}));
        }
        $self->{output}->perfdata_add(
            label => 'ctrlfan', unit => 'rpm',
            nlabel => 'hardware.controller.fan.speed.rpm',
            instances => $instance,
            value => $result->{scCtlrFanCurrentRpm},
            warning => $warn,
            critical => $crit, 
            min => 0
        );
    }
}

1;
