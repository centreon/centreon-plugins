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

package hardware::server::fujitsu::snmp::mode::components::psu;

use strict;
use warnings;

my $map_psu_status = {
    1 => 'unknown', 2 => 'not-present', 3 => 'ok', 4 => 'failed', 5 => 'ac-fail', 6 => 'dc-fail',
    7 => 'critical-temperature', 8 => 'not-manageable', 9 => 'fan-failure-predicted', 10 => 'fan-failure',
    11 => 'power-safe-mode', 12 => 'non-redundant-dc-fail', 13 => 'non-redundant-ac-fail',
};

my $mapping = {
    sc => {
        powerSupplyUnitStatus          => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.11.2.1.3', map => $map_psu_status },
        powerSupplyUnitDesignation     => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.11.2.1.4' },
    },
    sc2 => {
        sc2PowerSupplyDesignation   => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.2.1.3' },
        sc2PowerSupplyStatus        => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.2.1.5', map => $map_psu_status },
        sc2psPowerSupplyLoad        => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.2.1.6' },
    },
};
my $oid_sc2PowerSupply = '.1.3.6.1.4.1.231.2.10.2.2.10.6.2.1';
my $oid_powerSupplyUnits = '.1.3.6.1.4.1.231.2.10.2.2.5.11.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sc2PowerSupply }, { oid => $oid_powerSupplyUnits };
}

sub check_psu {
    my ($self, %options) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{$options{status}}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{$options{status}} =~ /not-present|not-available/i &&
                 $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{$options{name}}, $result->{$options{status}}, $instance, $result->{$options{current}}
                                    ));

        $exit = $self->get_severity(section => 'psu', value => $result->{$options{status}});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $result->{$options{name}}, $result->{$options{status}}));
        }
     
        next if (!defined($result->{$options{current}}) || $result->{$options{current}} == 0);
     
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'power', instance => $instance, value => $result->{$options{current}});
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' is %s W", $result->{$options{name}}, $result->{$options{current}}));
        }
        $self->{output}->perfdata_add(
            label => 'power', unit => 'W',
            nlabel => 'hardware.powersupply.power.watt',
            instances => $result->{$options{name}},
            value => $result->{$options{current}},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking poer supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    if (defined($self->{results}->{$oid_sc2PowerSupply}) && scalar(keys %{$self->{results}->{$oid_sc2PowerSupply}}) > 0) {
        check_psu($self, entry => $oid_sc2PowerSupply, mapping => $mapping->{sc2}, name => 'sc2PowerSupplyDesignation',
            current => 'sc2psPowerSupplyLoad', status => 'sc2PowerSupplyStatus');
    } else {
        check_psu($self, entry => $oid_powerSupplyUnits, mapping => $mapping->{sc}, name => 'powerSupplyUnitDesignation', 
            status => 'powerSupplyUnitStatus');
    }
}

1;
