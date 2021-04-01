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

package hardware::server::huawei::ibmc::snmp::mode::components::memory;

use strict;
use warnings;

my %map_status = (
    1 => 'ok',
    2 => 'minor',
    3 => 'major',
    4 => 'critical',
    5 => 'absence',
    6 => 'unknown',
);

my $mapping = {
    memoryStatus               => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.16.50.1.6', map => \%map_status },
    memoryDevicename           => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.16.50.1.10' },
};
my $oid_memoryDescriptionEntry = '.1.3.6.1.4.1.2011.2.235.1.1.16.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_memoryDescriptionEntry,
        start => $mapping->{memoryStatus}->{oid},
        end => $mapping->{memoryDevicename}->{oid},
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memory");
    $self->{components}->{memory} = {name => 'memorys', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_memoryDescriptionEntry}})) {
        next if ($oid !~ /^$mapping->{memoryStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_memoryDescriptionEntry}, instance => $instance);

        next if ($self->check_filter(section => 'memory', instance => $instance));
        next if ($result->{memoryStatus} =~ /absence/);
        $self->{components}->{memory}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Memory '%s' status is '%s' [instance = %s]",
                                    $result->{memoryDevicename}, $result->{memoryStatus}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'memory', value => $result->{memoryStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory '%s' status is '%s'", $result->{memoryDevicename}, $result->{memoryStatus}));
        }
    }
}

1;
