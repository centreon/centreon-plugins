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

package hardware::server::fujitsu::snmp::mode::components::voltage;

use strict;
use warnings;

my $map_sc_voltage_status = {
    1 => 'unknown', 2 => 'not-available', 3 => 'ok',
    4 => 'too-low', 5 => 'too-high', 6 => 'out-of-range',
    7 => 'battery-prefailure',
};
my $map_sc2_voltage_status = {
    1 => 'unknown', 2 => 'not-available', 3 => 'ok',
    4 => 'too-low', 5 => 'too-high', 6 => 'out-of-range',
    7 => 'warning',
};

my $mapping = {
    sc => {
        sniScVoltageStatus          => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.11.4.1.3', map => $map_sc_voltage_status },
        sniScVoltageDesignation     => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.11.4.1.4' },
        sniScVoltageCurrentValue    => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.11.4.1.7' },
    },
    sc2 => {
        sc2VoltageDesignation   => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.3.1.3' },
        sc2VoltageStatus        => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.3.1.4', map => $map_sc2_voltage_status },
        sc2VoltageCurrentValue  => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.3.1.5' },
    },
};
my $oid_sc2Voltages = '.1.3.6.1.4.1.231.2.10.2.2.10.6.3.1';
my $oid_sniScVoltages = '.1.3.6.1.4.1.231.2.10.2.2.5.11.4.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sc2Voltages, end => $mapping->{sc2}->{sc2VoltageCurrentValue} }, { oid => $oid_sniScVoltages };
}

sub check_voltage {
    my ($self, %options) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{$options{status}}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        
        next if ($self->check_filter(section => 'voltage', instance => $instance));
        next if ($result->{$options{status}} =~ /not-present|not-available/i &&
                 $self->absent_problem(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $result->{$options{current}} = $result->{$options{current}} / 1000 if (defined($result->{$options{current}}));

        $self->{output}->output_add(long_msg => sprintf("voltage '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{$options{name}}, $result->{$options{status}}, $instance, $result->{$options{current}}
                                    ));

        $exit = $self->get_severity(section => 'voltage', value => $result->{$options{status}});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' status is '%s'", $result->{$options{name}}, $result->{$options{status}}));
        }
     
        next if (!defined($result->{$options{current}}));
     
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{$options{current}});
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' is %s V", $result->{$options{name}}, $result->{$options{current}}));
        }
        $self->{output}->perfdata_add(
            label => 'voltage', unit => 'V',
            nlabel => 'hardware.voltage.volt',
            instances => $result->{$options{name}},
            value => $result->{$options{current}},
            warning => $warn,
            critical => $crit,
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    if (defined($self->{results}->{$oid_sc2Voltages}) && scalar(keys %{$self->{results}->{$oid_sc2Voltages}}) > 0) {
        check_voltage($self, entry => $oid_sc2Voltages, mapping => $mapping->{sc2}, name => 'sc2VoltageDesignation',
            current => 'sc2VoltageCurrentValue', status => 'sc2VoltageStatus');
    } else {
        check_voltage($self, entry => $oid_sniScVoltages, mapping => $mapping->{sc}, name => 'sniScVoltageDesignation', 
            current => 'sniScVoltageCurrentValue', status => 'sniScVoltageStatus');
    }
}

1;
