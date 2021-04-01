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

package hardware::server::dell::cmc::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_capable = (
    1 => 'absent', 
    2 => 'none', 
    3 => 'basic', 
);

# In MIB 'DELL-RAC-MIB'
my $mapping = {
    drsPSULocation => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.3' },
    drsPSUMonitoringCapable => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.4', map => \%map_psu_capable },
    drsPSUVoltsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.5', section => 'voltage', label => 'voltage', unit => 'volt' },
    drsPSUAmpsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.6', section => 'current', label => 'current', unit => 'ampere' },
    drsPSUWattsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.7', section => 'power', label => 'power', unit => 'watt' },
};
my $oid_drsCMCPSUTableEntry = '.1.3.6.1.4.1.674.10892.2.4.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_drsCMCPSUTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_drsCMCPSUTableEntry}})) {
        next if ($oid !~ /^$mapping->{drsPSUMonitoringCapable}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_drsCMCPSUTableEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{drsPSUMonitoringCapable} !~ /basic/i);
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s': power %s W, current %s A, voltage %s V [instance: %s].",
                                    $result->{drsPSULocation}, $result->{drsPSUWattsReading}, $result->{drsPSUAmpsReading}, $result->{drsPSUVoltsReading},
                                    $instance
                                    ));
        foreach my $probe (('drsPSUVoltsReading', 'drsPSUAmpsReading', 'drsPSUWattsReading')) {
            next if (!defined($result->{$probe}));
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu.' . $mapping->{$probe}->{section}, instance => $instance, value => $result->{$probe});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' %s is %s%s", $result->{drsPSULocation}, 
                                                                 $mapping->{$probe}->{section}, $result->{$probe}, $mapping->{$probe}->{unit}));
            }
            $self->{output}->perfdata_add(
                label => 'psu_' . $mapping->{$probe}->{label}, unit => $mapping->{$probe}->{unit},
                nlabel => 'hardware.' . $mapping->{$probe}->{label} . '.' . $mapping->{$probe}->{unit},
                instances => $instance,
                value => $result->{$probe},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
