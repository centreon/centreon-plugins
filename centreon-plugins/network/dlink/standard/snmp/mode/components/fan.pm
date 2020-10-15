#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

my $map_status_equipment = {
    0 => 'other', 1 => 'working',
    2 => 'fail', 3 => 'speed-0',
    4 => 'speed-low', 5 => 'speed-middle',
    6 => 'speed-high'
};
my $map_status = {
    1 => 'ok', 2 => 'fault'
};

my $mapping_equipment = {
    swFanStatus => { oid => '.1.3.6.1.4.1.171.12.11.1.7.1.3', map => $map_status_equipment },
    swFanSpeed  => { oid => '.1.3.6.1.4.1.171.12.11.1.7.1.6' }
};
my $oid_swFanEntry = '.1.3.6.1.4.1.171.12.11.1.7.1';

my $mapping_industrial = {
    description => { oid => '.1.3.6.1.4.1.171.14.5.1.1.2.1.3' }, # dEntityExtEnvFanDescr
    status      => { oid => '.1.3.6.1.4.1.171.14.5.1.1.2.1.4', map => $map_status } # dEntityExtEnvFanStatus
};
my $oid_dEntityExtEnvFanEntry = '.1.3.6.1.4.1.171.14.5.1.1.2.1';

my $mapping_common = {
    description => { oid => '.1.3.6.1.4.1.171.17.5.1.1.2.1.3' }, # esEntityExtEnvFanDescr
    status      => { oid => '.1.3.6.1.4.1.171.17.5.1.1.2.1.4', map => $map_status } # esEntityExtEnvFanStatus
};
my $oid_esEntityExtEnvFanEntry = '.1.3.6.1.4.1.171.17.5.1.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $oid_swFanEntry, start => $mapping_equipment->{swFanStatus}->{oid} },
        { oid => $oid_dEntityExtEnvFanEntry, start => $mapping_industrial->{description}->{oid} },
        { oid => $oid_esEntityExtEnvFanEntry, start => $mapping_common->{description}->{oid} }
    ;
}

sub check_fan_equipment {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_swFanEntry}})) {
        next if ($oid !~ /^$mapping_equipment->{swFanStatus}->{oid}\.(\d+)\.(\d+)$/);
        my ($unit_id, $fan_id) = ($1, $2);
        my $instance = $1 . '.' . $2;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_equipment, results => $self->{results}->{$oid_swFanEntry}, instance => $instance);

        my $description = 'unit' . $unit_id . ':fan' . $fan_id;
        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [instance: %s, speed: %s]",
                $description,
                $result->{swFanStatus},
                $instance,
                $result->{swFanSpeed}
            )
        );
        my $exit = $self->get_severity(section => 'fan', value => $result->{swFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan '%s' status is %s",
                    $description, $result->{swFanStatus}
                )
            );
        }
        
        if (defined($result->{swFanSpeed})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{swFanSpeed});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "fan '%s' speed is %s rpm",
                        $description,
                        $result->{swFanSpeed}
                    )
                );
            }
            $self->{output}->perfdata_add(
                unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => ['unit' . $unit_id, 'fan' . $fan_id],
                value => $result->{swFanSpeed},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

sub check_fan {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $options{entry} }})) {
        next if ($oid !~ /^$options{mapping}->{status}->{oid}\.(\d+)\.(\d+)$/);
        my ($unit_id, $fan_id) = ($1, $2);
        my $instance = $1 . '.' . $2;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{ $options{entry} }, instance => $instance);

        my $description = 'unit' . $unit_id . ':fan' . $fan_id;
        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is '%s' [instance: %s, description: %s]",
                $description,
                $result->{status},
                $instance,
                $result->{description}
            )
        );
        my $exit = $self->get_severity(section => 'fan', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan '%s' status is '%s'",
                    $description, $result->{status}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    check_fan_equipment($self);
    check_fan($self, entry => $oid_dEntityExtEnvFanEntry, mapping => $mapping_industrial);
    check_fan($self, entry => $oid_esEntityExtEnvFanEntry, mapping => $mapping_common);
}

1;
