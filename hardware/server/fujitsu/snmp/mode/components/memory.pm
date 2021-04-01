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

package hardware::server::fujitsu::snmp::mode::components::memory;

use strict;
use warnings;

my $map_sc_memory_status = {
    1 => 'unknown', 2 => 'error', 3 => 'ok', 4 => 'not-available', 5 => 'fail',
    6 => 'prefailure-warning', 7 => 'hot-spare', 8 => 'mirror', 
    9 => 'disabled', 10 => 'raid',
};
my $map_sc2_memory_status = {
    1 => 'unknown', 2 => 'not-present', 3 => 'ok', 4 => 'disabled', 5 => 'error', 6 => 'failed',
    7 => 'prefailure-predicted', 8 => 'hot-spare', 9 => 'mirror', 10 => 'raid', 11 => 'hidden',
};

my $mapping = {
    sc => {
        memModuleStatus         => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.4.10.1.3', map => $map_sc_memory_status },
    },
    sc2 => {
        sc2memModuleDesignation => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.5.1.3' },
        sc2memModuleStatus      => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.5.1.4', map => $map_sc2_memory_status },
    },
};
my $oid_sc2MemoryModules = '.1.3.6.1.4.1.231.2.10.2.2.10.6.5.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sc2MemoryModules, end => $mapping->{sc2}->{sc2memModuleStatus} }, { oid => $mapping->{sc}->{memModuleStatus}->{oid} };
}

sub check_memory {
    my ($self, %options) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{$options{status}}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        $result->{instance} = $instance;
        
        next if ($self->check_filter(section => 'memory', instance => $instance));
        next if ($result->{$options{status}} =~ /not-present|not-available/i &&
                 $self->absent_problem(section => 'memory', instance => $instance));
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("memory '%s' status is '%s' [instance = %s]",
                                    $result->{$options{name}}, $result->{$options{status}}, $instance,
                                    ));

        $exit = $self->get_severity(section => 'memory', value => $result->{$options{status}});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory '%s' status is '%s'", $result->{$options{name}}, $result->{$options{status}}));
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memories");
    $self->{components}->{memory} = {name => 'memories', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    if (defined($self->{results}->{$oid_sc2MemoryModules}) && scalar(keys %{$self->{results}->{$oid_sc2MemoryModules}}) > 0) {
        check_memory($self, entry => $oid_sc2MemoryModules, mapping => $mapping->{sc2}, name => 'sc2memModuleDesignation',
            status => 'sc2memModuleStatus');
    } else {
        check_memory($self, entry => $mapping->{sc}->{memModuleStatus}, mapping => $mapping->{sc}, name => 'instance', 
            status => 'memModuleStatus');
    }
}

1;
