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

package hardware::server::ibm::bladecenter::snmp::mode::components::systemhealth;

use strict;
use warnings;

# In MIB 'mmblade.mib' and 'cme.mib'
my $oid_systemHealthStat = '.1.3.6.1.4.1.2.3.51.2.2.7.1';

my %map_systemhealth_state = (
    0 => 'critical',
    2 => 'nonCritical',
    4 => 'systemLevel',
    255 => 'normal',
);

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_systemHealthStat };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking system health");
    $self->{components}->{systemhealth} = {name => 'system-health', total => 0, skip => 0};
    return if ($self->check_filter(section => 'systemhealth'));

    return if (!defined($self->{results}->{$oid_systemHealthStat}->{$oid_systemHealthStat . '.0'}) ||
               !defined($map_systemhealth_state{$self->{results}->{$oid_systemHealthStat}->{$oid_systemHealthStat . '.0'}}));
    
    my $value = $map_systemhealth_state{$self->{results}->{$oid_systemHealthStat}->{$oid_systemHealthStat . '.0'}};
    $self->{components}->{systemhealth}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("System health state is %s", 
                                                    $value));
    my $exit = $self->get_severity(section => 'systemhealth', value => $value);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("System health state is %s", 
                                                         $value));
    }
}

1;