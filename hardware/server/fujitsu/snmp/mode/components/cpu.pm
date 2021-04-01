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

package hardware::server::fujitsu::snmp::mode::components::cpu;

use strict;
use warnings;

my $map_sc_cpu_status = {
    1 => 'unknown', 2 => 'disabled', 3 => 'ok', 4 => 'not-present', 5 => 'error',
    6 => 'fail', 7 => 'missing-termination', 8 => 'prefailure-warning',
};
my $map_sc2_cpu_status = {
    1 => 'unknown', 2 => 'not-present', 3 => 'ok', 4 => 'disabled', 5 => 'error',
    6 => 'failed', 7 => 'missing-termination', 8 => 'prefailure-warning',
};

my $mapping = {
    sc => {
        cpuStatus         => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.4.1.1.6', map => $map_sc_cpu_status },
    },
    sc2 => {
        sc2cpuDesignation => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.4.1.3' },
        sc2cpuStatus      => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.6.4.1.4', map => $map_sc2_cpu_status },
    },
};
my $oid_sc2CPUs = '.1.3.6.1.4.1.231.2.10.2.2.10.6.4.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_sc2CPUs, end => $mapping->{sc2}->{sc2cpuStatus} }, { oid => $mapping->{sc}->{cpuStatus}->{oid} };
}

sub check_cpu {
    my ($self, %options) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{$options{status}}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        $result->{instance} = $instance;
        
        next if ($self->check_filter(section => 'cpu', instance => $instance));
        next if ($result->{$options{status}} =~ /not-present|not-available/i &&
                 $self->absent_problem(section => 'cpu', instance => $instance));
        $self->{components}->{cpu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("cpu '%s' status is '%s' [instance = %s]",
                                    $result->{$options{name}}, $result->{$options{status}}, $instance,
                                    ));

        $exit = $self->get_severity(section => 'cpu', value => $result->{$options{status}});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Cpu '%s' status is '%s'", $result->{$options{name}}, $result->{$options{status}}));
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = {name => 'cpu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    if (defined($self->{results}->{$oid_sc2CPUs}) && scalar(keys %{$self->{results}->{$oid_sc2CPUs}}) > 0) {
        check_cpu($self, entry => $oid_sc2CPUs, mapping => $mapping->{sc2}, name => 'sc2cpuDesignation',
            status => 'sc2cpuStatus');
    } else {
        check_cpu($self, entry => $mapping->{sc}->{cpuStatus}, mapping => $mapping->{sc}, name => 'instance', 
            status => 'cpuStatus');
    }
}

1;
