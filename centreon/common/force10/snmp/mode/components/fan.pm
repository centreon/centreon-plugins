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

package centreon::common::force10::snmp::mode::components::fan;

use strict;
use warnings;

my $map_status = {
    1 => 'up',
    2 => 'down',
    3 => 'absent'
};

my $mapping = {
    sseries => {
        status => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.4.1.2', map => $map_status } # chSysFanTrayOperStatus
    },
    mseries => {
        status => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.3.1.2', map => $map_status } # chSysFanTrayOperStatus
    },
    zseries => {
        status => { oid => '.1.3.6.1.4.1.6027.3.25.1.2.7.1.2', map => $map_status } # chSysFanTrayOperStatus
    },
    os9 => {
        status => { oid => '.1.3.6.1.4.1.6027.3.26.1.4.7.1.4', map => $map_status } # dellNetFanTrayOperStatus
    }
};

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        { oid => $mapping->{sseries}->{status}->{oid} },
        { oid => $mapping->{mseries}->{status}->{oid} },
        { oid => $mapping->{zseries}->{status}->{oid} },
        { oid => $mapping->{os9}->{status}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $name (keys %$mapping) {
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{$name}->{status}->{oid} }})) {
            next if ($oid !~ /^$mapping->{$name}->{status}->{oid}\.(.*)$/);
            my $instance = $1;
            my $result = $self->{snmp}->map_instance(mapping => $mapping->{$name}, results => $self->{results}->{ $mapping->{$name}->{status}->{oid} }, instance => $instance);

            next if ($result->{status} =~ /absent/i && 
                     $self->absent_problem(section => 'fan', instance => $instance));
            next if ($self->check_filter(section => 'fan', instance => $instance));
            $self->{components}->{fan}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "fan '%s' status is '%s' [instance: %s]", 
                    $instance, $result->{status}, 
                    $instance
                )
            );
            my $exit = $self->get_severity(section => 'fan', value => $result->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Fan '%s' status is '%s'", 
                        $instance, $result->{status}
                    )
                );
            }
        }
    }
}

1;
