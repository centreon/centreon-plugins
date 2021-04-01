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

package hardware::server::lenovo::xcc::snmp::mode::components::voltage;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    voltDescr               => { oid => '.1.3.6.1.4.1.19046.11.1.1.2.2.1.2' },
    voltReading             => { oid => '.1.3.6.1.4.1.19046.11.1.1.2.2.1.3' },
    voltCritLimitHigh       => { oid => '.1.3.6.1.4.1.19046.11.1.1.2.2.1.6' },
    voltNonCritLimitHigh    => { oid => '.1.3.6.1.4.1.19046.11.1.1.2.2.1.7' },
    voltCritLimitLow        => { oid => '.1.3.6.1.4.1.19046.11.1.1.2.2.1.9' },
    voltNonCritLimitLow     => { oid => '.1.3.6.1.4.1.19046.11.1.1.2.2.1.10' },
    voltHealthStatus        => { oid => '.1.3.6.1.4.1.19046.11.1.1.2.2.1.11' },
};
my $oid_voltEntry = '.1.3.6.1.4.1.19046.11.1.1.2.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_voltEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_voltEntry}})) {
        next if ($oid !~ /^$mapping->{voltDescr}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_voltEntry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $result->{voltDescr} = centreon::plugins::misc::trim($result->{voltDescr});
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("voltage '%s' status is %s [instance: %s][value: %s].",
                                    $result->{voltDescr}, $result->{voltHealthStatus}, $instance, $result->{voltReading}));
        
        my $exit = $self->get_severity(label => 'default', section => 'voltage', value => $result->{voltHealthStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' status is '%s'", $result->{voltDescr}, $result->{voltHealthStatus}));
        }
        
        next if (!defined($result->{voltReading}));
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{voltReading});
        if ($checked == 0) {
            my $warn_th = ($result->{voltNonCritLimitLow} =~ /\d+(\.\d+)?/ ? $result->{voltNonCritLimitLow} : '') . ':' . ($result->{voltNonCritLimitHigh} =~ /\d+(\.\d+)?/ ? $result->{voltNonCritLimitHigh} : '');
            my $crit_th = ($result->{voltCritLimitLow} =~ /\d+(\.\d+)?/ ? $result->{voltCritLimitLow} : '') . ':' . ($result->{voltCritLimitHigh} =~ /\d+(\.\d+)?/ ? $result->{voltCritLimitHigh} : '');
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th) if ($warn_th ne ':');
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th) if ($crit_th ne ':');
            $exit = $self->{perfdata}->threshold_check(
                value => $result->{voltReading},
                threshold => [ { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' },
                               { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' } ]);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);    
        }
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Voltage '%s' is %s", $result->{voltDescr}, $result->{voltReading}));
        }
        $self->{output}->perfdata_add(
            label => 'volt',
            nlabel => 'hardware.voltage.volt',
            instances => $result->{voltDescr},
            value => $result->{voltReading},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
