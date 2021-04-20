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

package storage::qnap::snmp::mode::components::fan;

use strict;
use warnings;

my $map_status = {
    0 => 'ok',
    -1 => 'fail'
};

# In MIB 'NAS.mib'
my $mapping = {
    description => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2.1.2' },
    status      => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2.1.4', map => $map_status },
    speed       => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2.1.5' }
};
my $entry = '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2';

sub load {
    my ($self) = @_;

    if (defined($self->{option_results}->{legacy})) {
        $mapping = {
            description => { oid => '.1.3.6.1.4.1.24681.1.2.15.1.2' }, # sysFanDescr
            speed       => { oid => '.1.3.6.1.4.1.24681.1.2.15.1.3' } # sysFanSpeed
        };
        $entry = '.1.3.6.1.4.1.24681.1.2.15';
    }

    push @{$self->{request}}, {
        oid => $entry,
        start => $mapping->{description}->{oid},
        end => $mapping->{speed}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$entry}})) {
        next if ($oid !~ /^$mapping->{description}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$entry}, instance => $instance);

        $result->{speed} = defined($result->{speed}) ? $result->{speed} : 'unknown';

        next if ($self->check_filter(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' [instance: %s, speed: %s] status is %s.",
                $result->{description}, $instance, $result->{speed}, defined($result->{status}) ? $result->{status} : '-'
            )
        );

        if (defined($result->{status})) {
            my $exit = $self->get_severity(section => 'fan', instance => $instance, value => $result->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Fan '%s' status is %s.", $result->{description}, $result->{status}
                    )
                );
            }
        }

        if ($result->{speed} =~ /([0-9]+)\s*rpm/i) {
            my $fan_speed_value = $1;
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fan_speed_value);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Fan '%s' speed is %s rpm", $result->{description}, $fan_speed_value
                    )
                );
            }
            $self->{output}->perfdata_add(
                nlabel => 'hardware.fan.speed.rpm',
                unit => 'rpm',
                instances => $instance,
                value => $fan_speed_value,
                min => 0
            );
        }
    }
}

1;
