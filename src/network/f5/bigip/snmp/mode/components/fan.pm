#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::snmp::mode::components::fan;

use strict;
use warnings;

my %map_status = (
    0 => 'bad',
    1 => 'good',
    2 => 'notPresent',
);

my $mapping = {
    sysChassisFanStatus => { oid => '.1.3.6.1.4.1.3375.2.1.3.2.1.2.1.2', map => \%map_status },
    sysChassisFanSpeed => { oid => '.1.3.6.1.4.1.3375.2.1.3.2.1.2.1.3' },
};
my $oid_sysChassisFanEntry = '.1.3.6.1.4.1.3375.2.1.3.2.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sysChassisFanEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_sysChassisFanEntry}})) {
        next if ($oid !~ /^$mapping->{sysChassisFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sysChassisFanEntry}, instance => $instance);
    
        next if ($result->{sysChassisFanStatus} =~ /notPresent/i && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        next if ($self->check_filter(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is '%s' [instance: %s, speed: %s].", 
                $instance, $result->{sysChassisFanStatus}, $instance,
                defined($result->{sysChassisFanSpeed}) ? $result->{sysChassisFanSpeed} : '-'
            )
        );

        my $exit = $self->get_severity(section => 'fan', value => $result->{sysChassisFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fan '%s' status is '%s'", 
                    $instance, $result->{sysChassisFanStatus}
                )
            );
        }
        
        if (defined($result->{sysChassisFanSpeed}) && $result->{sysChassisFanSpeed} =~ /[0-9]/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{sysChassisFanSpeed});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf("fan speed '%s' is %s rpm", $instance, $result->{sysChassisFanSpeed})
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.fan.speed.rpm',
                unit => 'rpm',
                instances => $instance,
                value => $result->{sysChassisFanSpeed},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
