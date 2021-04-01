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

package network::checkpoint::snmp::mode::components::raiddisk;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_states_disk = (
    0 => 'online',
    1 => 'missing',
    2 => 'not_compatible',
    3 => 'disc_failed',
    4 => 'initializing',
    5 => 'offline_requested',
    6 => 'failed_requested',
    7 => 'unconfigured_good_spun_up',
    8 => 'unconfigured_good_spun_down',
    9 => 'unconfigured_bad',
    10 => 'hotspare',
    11 => 'drive_offline',
    12 => 'rebuild',
    13 => 'failed',
    14 => 'copyback',
    255 => 'other_offline',
);

my $mapping = {
    raidDiskProductID => { oid => '.1.3.6.1.4.1.2620.1.6.7.7.2.1.6' },
    raidDiskState => { oid => '.1.3.6.1.4.1.2620.1.6.7.7.2.1.9', map => \%map_states_disk },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{raidDiskProductID}->{oid} }, 
        { oid => $mapping->{raidDiskState}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raid disks");
    $self->{components}->{raiddisk} = {name => 'raiddisk', total => 0, skip => 0};
    return if ($self->check_filter(section => 'raiddisk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{raidDiskProductID}->{oid}}})) {
        $oid =~ /^$mapping->{raidDiskProductID}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results =>
												$self->{results}->{$mapping->{raidDiskState}->{oid}}, instance => $instance);
    
        next if ($self->check_filter(section => 'raiddisk', instance => $instance));

        my $name = centreon::plugins::misc::trim($self->{results}->{$mapping->{raidDiskProductID}->{oid}}->{$oid});
        $self->{components}->{raiddisk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("raid disk '%s' status is '%s'",
                                    $name, $result->{raidDiskState}));
        my $exit = $self->get_severity(section => 'raiddisk', value => $result->{raidDiskState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Raid disk '%s' status is '%s'", 
                                            $name, $result->{raidDiskState}));
        }
    }
}

1;
