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

package hardware::server::lenovo::xcc::snmp::mode::components::raidvolume;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    raidVolumeName      => { oid => '.1.3.6.1.4.1.19046.11.1.1.13.1.7.1.2' },
    raidVolumeStatus    => { oid => '.1.3.6.1.4.1.19046.11.1.1.13.1.7.1.4' },
};
my $oid_raidVolumeEntry = '.1.3.6.1.4.1.19046.11.1.1.13.1.7.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_raidVolumeEntry, end => $mapping->{raidVolumeStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raid volumes");
    $self->{components}->{raidvolume} = { name => 'raidvolume', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'raidvolume'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raidVolumeEntry}})) {
        next if ($oid !~ /^$mapping->{raidVolumeName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_raidVolumeEntry}, instance => $instance);

        next if ($self->check_filter(section => 'raidvolume', instance => $instance));
        $result->{raidVolumeName} = centreon::plugins::misc::trim($result->{raidVolumeName});
        $self->{components}->{raidvolume}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("raid volume '%s' status is %s [instance: %s].",
                                    $result->{raidVolumeName}, $result->{raidVolumeStatus}, $instance));
        
        my $exit = $self->get_severity(section => 'raidvolume', value => $result->{raidVolumeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Raid volume '%s' status is '%s'", $result->{raidVolumeName}, $result->{raidVolumeStatus}));
        }
    }
}

1;
