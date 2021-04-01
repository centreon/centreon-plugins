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

package storage::dell::compellent::snmp::mode::components::ctrlvoltage;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scCtlrVoltageStatus    => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1.3', map => \%map_sc_status },
    scCtlrVoltageName      => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1.4' },
    scCtlrVoltageCurrentV  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1.5' },
    scCtlrVoltageWarnLwrV  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1.8' },
    scCtlrVoltageWarnUprV  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1.9' },
    scCtlrVoltageCritLwrV  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1.10' },
    scCtlrVoltageCritUprV  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1.11' },
};
my $oid_scCtlrVoltageEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.18.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scCtlrVoltageEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking controller voltages");
    $self->{components}->{ctrlvoltage} = {name => 'controller voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ctrlvoltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scCtlrVoltageEntry}})) {
        next if ($oid !~ /^$mapping->{scCtlrVoltageStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scCtlrVoltageEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'ctrlvoltage', instance => $instance));

        $self->{components}->{ctrlvoltage}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("controller voltage '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{scCtlrVoltageName}, $result->{scCtlrVoltageStatus}, $instance, 
                                    $result->{scCtlrVoltageCurrentV}));
        
        my $exit = $self->get_severity(label => 'default', section => 'ctrlvoltage', value => $result->{scCtlrVoltageStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Controller voltage '%s' status is '%s'", $result->{scCtlrVoltageName}, $result->{scCtlrVoltageStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'ctrlvoltage', instance => $instance, value => $result->{scCtlrVoltageCurrentV});
        if ($checked == 0) {
            $result->{scCtlrVoltageWarnLwrV} = (defined($result->{scCtlrVoltageWarnLwrV}) && $result->{scCtlrVoltageWarnLwrV} =~ /[0-9]/) ?
                $result->{scCtlrVoltageWarnLwrV} : '';
            $result->{scCtlrVoltageCritLwrV} = (defined($result->{scCtlrVoltageCritLwrV}) && $result->{scCtlrVoltageCritLwrV} =~ /[0-9]/) ?
                $result->{scCtlrVoltageCritLwrV} : '';
            $result->{scCtlrVoltageWarnUprV} = (defined($result->{scCtlrVoltageWarnUprV}) && $result->{scCtlrVoltageWarnUprV} =~ /[0-9]/) ?
                $result->{scCtlrVoltageWarnUprV} : '';
            $result->{scCtlrVoltageCritUprV} = (defined($result->{scCtlrVoltageCritUprV}) && $result->{scCtlrVoltageCritUprV} =~ /[0-9]/) ?
                $result->{scCtlrVoltageCritUprV} : '';
            my $warn_th = $result->{scCtlrVoltageWarnLwrV} . ':' . $result->{scCtlrVoltageWarnUprV};
            my $crit_th = $result->{scCtlrVoltageCritLwrV} . ':' . $result->{scCtlrVoltageCritUprV};
            $self->{perfdata}->threshold_validate(label => 'warning-ctrlvoltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-ctrlvoltage-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-ctrlvoltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-ctrlvoltage-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Controller voltage '%s' is %s V", $result->{scCtlrVoltageName}, $result->{scCtlrVoltageCurrentV}));
        }
        $self->{output}->perfdata_add(
            label => 'ctrlvoltage', unit => 'V',
            nlabel => 'hardware.controller.voltage.volt',
            instances => $instance,
            value => $result->{scCtlrVoltageCurrentV},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
