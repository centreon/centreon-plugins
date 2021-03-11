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

package network::hirschmann::standard::snmp::mode::components::psu;

use strict;
use warnings;

my $map_hios_psu_state = {
    1 => 'present', 
    2 => 'defective', 
    3 => 'notInstalled', 
    4 => 'unknown'
};
my $map_classic_psu_state = {
    1 => 'ok', 
    2 => 'failed', 
    3 => 'notInstalled', 
    4 => 'unknown'
};
my $map_classic_psu_mon = {
    1 => 'error', 2 => 'ignore'
};
my $mapping_classic_devmon = {
    ps1_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.9', map => $map_classic_psu_mon }, # hmDevMonSensePS1State
    ps2_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.10', map => $map_classic_psu_mon }, # hmDevMonSensePS2State
    ps3_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.14', map => $map_classic_psu_mon }, # hmDevMonSensePS3State
    ps4_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.15', map => $map_classic_psu_mon }, # hmDevMonSensePS4State
    ps5_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.17', map => $map_classic_psu_mon }, # hmDevMonSensePS5State
    ps6_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.18', map => $map_classic_psu_mon }, # hmDevMonSensePS6State
    ps7_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.19', map => $map_classic_psu_mon }, # hmDevMonSensePS7State
    ps8_mon => { oid => '.1.3.6.1.4.1.248.14.2.12.3.1.20', map => $map_classic_psu_mon } # hmDevMonSensePS8State
};
my $mapping_classic_psu = {
    psu_state => { oid => '.1.3.6.1.4.1.248.14.1.2.1.3', map => $map_classic_psu_state } # hmPSState
};
my $oid_classic_devmon_entry = '.1.3.6.1.4.1.248.14.2.12.3.1'; # hmDevMonConfigEntry

my $mapping_hios_psu = {
    psu_state => { oid => '.1.3.6.1.4.1.248.11.11.1.1.1.1.2', map => $map_hios_psu_state } # hm2PSState
};

sub load {
    my ($self) = @_;
    
    push @{$self->{myrequest}->{classic}}, 
        { oid => $oid_classic_devmon_entry, start => $mapping_classic_devmon->{ps1_mon}->{oid} },
        { oid => $mapping_classic_psu->{psu_state}->{oid} };
    push @{$self->{myrequest}->{hios}}, 
        { oid => $mapping_hios_psu->{psu_state}->{oid} };
}

sub check_psu_classic {
    my ($self) = @_;

    my $devmons = {};
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_classic_psu->{psu_state}->{oid} }})) {
        next if ($oid !~ /^$mapping_classic_psu->{psu_state}->{oid}\.(\d+)\.(\d+)$/);
        my $instance = $1 . '.' . $2;
        my ($sysid, $psid) = ($1, $2);
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping_classic_psu,
            results => $self->{results}->{ $mapping_classic_psu->{psu_state}->{oid} },
            instance => $instance
        );

        if (!defined($devmons->{$sysid})) {
            $devmons->{$sysid} = $self->{snmp}->map_instance(
                mapping => $mapping_classic_devmon,
                results => $self->{results}->{$oid_classic_devmon_entry},
                instance => $sysid
            );
        }

        if (defined($devmons->{$sysid}->{'ps' . $psid . '_mon'}) && $devmons->{$sysid}->{'ps' . $psid . '_mon'} eq 'ignore') {
            $result->{psu_state} = 'ignore';
        }

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{psu_state} =~ /notInstalled/i && 
            $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is %s [instance: %s].",
                $instance, $result->{psu_state},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'psu', value => $result->{psu_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is %s",
                    $instance, $result->{psu_state}
                )
            );
        }
    }
}

sub check_psu_hios {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_hios_psu->{psu_state}->{oid} }})) {
        next if ($oid !~ /^$mapping_hios_psu->{psu_state}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(
            mapping => $mapping_hios_psu,
            results => $self->{results}->{ $mapping_hios_psu->{psu_state}->{oid} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{psu_state} =~ /notInstalled/i && 
            $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is %s [instance: %s].",
                $instance, $result->{psu_state},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'psu', value => $result->{psu_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is %s",
                    $instance, $result->{psu_state}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking power supplies');
    $self->{components}->{psu} = { name => 'psus', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    check_psu_classic($self) if ($self->{os_type} eq 'classic');
    check_psu_hios($self) if ($self->{os_type} eq 'hios');
}

1;
