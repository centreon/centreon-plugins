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

package network::dlink::standard::snmp::mode::components::fan;

use strict;
use warnings;

my %map_states = (
    0 => 'other',
    1 => 'working',
    2 => 'fail',
    3 => 'speed-0',
    4 => 'speed-low',
    5 => 'speed-middle',
    6 => 'speed-high',
);

# In MIB 'env_mib.mib'
my $mapping = {
    swFanStatus => { oid => '.1.3.6.1.4.1.171.12.11.1.7.1.3', map => \%map_states },
    swFanSpeed  => { oid => '.1.3.6.1.4.1.171.12.11.1.7.1.6' },
};
my $oid_swFanEntry = '.1.3.6.1.4.1.171.12.11.1.7.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_swFanEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_swFanEntry}})) {
        next if ($oid !~ /^$mapping->{swFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_swFanEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is %s [speed = %s].",
                                    $instance, $result->{swFanStatus}, $result->{swFanSpeed}
                                    ));
        my $exit = $self->get_severity(section => 'fan', value => $result->{swFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("fan '%s' status is %s",
                                                             $instance, $result->{swFanStatus}));
        }
        
        if (defined($result->{swFanSpeed})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{swFanSpeed});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("fan '%s' speed is %s rpm", $instance, $result->{swFanSpeed}));
            }
            $self->{output}->perfdata_add(
                label => "fan", unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => $instance,
                value => $result->{swFanSpeed},
                warning => $warn,
                critical => $crit, min => 0
            );
        }
    }
}

1;
