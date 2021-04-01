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

package storage::dell::compellent::snmp::mode::components::ctrltemp;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scCtlrTempStatus    => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1.3', map => \%map_sc_status },
    scCtlrTempName      => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1.4' },
    scCtlrTempCurrentC  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1.5' },
    scCtlrTempWarnLwrC  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1.8' },
    scCtlrTempWarnUprC  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1.9' },
    scCtlrTempCritLwrC  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1.10' },
    scCtlrTempCritUprC  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1.11' },
};
my $oid_scCtlrTempEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.19.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scCtlrTempEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking controller temperatures");
    $self->{components}->{ctrltemp} = {name => 'controller temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ctrltemp'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scCtlrTempEntry}})) {
        next if ($oid !~ /^$mapping->{scCtlrTempStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scCtlrTempEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'ctrltemp', instance => $instance));

        $self->{components}->{ctrltemp}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("controller temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{scCtlrTempName}, $result->{scCtlrTempStatus}, $instance, 
                                    $result->{scCtlrTempCurrentC}));
        
        my $exit = $self->get_severity(label => 'default', section => 'ctrltemp', value => $result->{scCtlrTempStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Controller temperature '%s' status is '%s'", $result->{scCtlrTempName}, $result->{scCtlrTempStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'ctrltemp', instance => $instance, value => $result->{scCtlrTempCurrentC});
        if ($checked == 0) {
            $result->{scCtlrTempWarnLwrC} = (defined($result->{scCtlrTempWarnLwrC}) && $result->{scCtlrTempWarnLwrC} =~ /[0-9]/) ?
                $result->{scCtlrTempWarnLwrC} : '';
            $result->{scCtlrTempCritLwrC} = (defined($result->{scCtlrTempCritLwrC}) && $result->{scCtlrTempCritLwrC} =~ /[0-9]/) ?
                $result->{scCtlrTempCritLwrC} : '';
            $result->{scCtlrTempWarnUprC} = (defined($result->{scCtlrTempWarnUprC}) && $result->{scCtlrTempWarnUprC} =~ /[0-9]/) ?
                $result->{scCtlrTempWarnUprC} : '';
            $result->{scCtlrTempCritUprC} = (defined($result->{scCtlrTempCritUprC}) && $result->{scCtlrTempCritUprC} =~ /[0-9]/) ?
                $result->{scCtlrTempCritUprC} : '';
            my $warn_th = $result->{scCtlrTempWarnLwrC} . ':' . $result->{scCtlrTempWarnUprC};
            my $crit_th = $result->{scCtlrTempCritLwrC} . ':' . $result->{scCtlrTempCritUprC};
            $self->{perfdata}->threshold_validate(label => 'warning-ctrltemp-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-ctrltemp-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-ctrltemp-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-ctrltemp-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Controller temperature '%s' is %s C", $result->{scCtlrTempName}, $result->{scCtlrTempCurrentC}));
        }
        $self->{output}->perfdata_add(
            label => 'ctrltemp', unit => 'C',
            nlabel => 'hardware.controller.temperature.celsius',
            instances => $instance,
            value => $result->{scCtlrTempCurrentC},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
