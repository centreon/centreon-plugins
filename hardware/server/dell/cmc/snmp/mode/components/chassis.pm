#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::cmc::snmp::mode::components::chassis;

use strict;
use warnings;

# In MIB 'DELL-RAC-MIB'
my $mapping = {
    drsWattsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.1.1.13', section => 'power', label => 'power', unit => 'watt' },
    drsAmpsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.1.1.14', section => 'current', label => 'current', unit => 'ampere' },
};
my $oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry = '.1.3.6.1.4.1.674.10892.2.4.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking chassis");
    $self->{components}->{chassis} = { name => 'chassis', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'chassis'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry}})) {
        next if ($oid !~ /^$mapping->{drsWattsReading}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry}, instance => $instance);

        next if ($self->check_filter(section => 'chassis', instance => $instance));
        $self->{components}->{chassis}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Chassis '%s': power %s W, current %s A [instance: %s].",
                                    $instance, $result->{drsWattsReading}, $result->{drsAmpsReading},
                                    $instance
                                    ));
        foreach my $probe (('drsWattsReading', 'drsAmpsReading')) {
            next if (!defined($result->{$probe}));
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'chassis.' . $mapping->{$probe}->{section}, instance => $instance, value => $result->{$probe});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Chassis '%s' %s is %s%s", $instance, 
                                                                 $mapping->{$probe}->{section}, $result->{$probe}, $mapping->{$probe}->{unit}));
            }
            $self->{output}->perfdata_add(
                label => 'chassis_' . $mapping->{$probe}->{label}, unit => $mapping->{$probe}->{unit},
                nlabel => 'hardware.chassis.' . $mapping->{$probe}->{label} . '.' . $mapping->{$probe}->{unit},
                instances => $instance,
                value => $result->{$probe},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
