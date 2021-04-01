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

package hardware::server::huawei::ibmc::snmp::mode::components::logicaldrive;

use strict;
use warnings;

my %map_state = (
    1 => 'offline',
    2 => 'partial degraded',
    3 => 'degraded',
    4 => 'optimal',
    255 => 'unknown',
);

my $mapping = {
    logicalDriveRAIDControllerIndex  => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.37.50.1.1' },
    logicalDriveIndex                => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.37.50.1.2' },
    logicalDriveState                => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.37.50.1.4', map => \%map_state },
};
my $oid_logicalDriveDescriptionEntry = '.1.3.6.1.4.1.2011.2.235.1.1.37.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_logicalDriveDescriptionEntry,
        end => $mapping->{logicalDriveState}->{oid},
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking logical drives");
    $self->{components}->{logicaldrive} = {name => 'logical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'logicaldrive'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_logicalDriveDescriptionEntry}})) {
        next if ($oid !~ /^$mapping->{logicalDriveState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_logicalDriveDescriptionEntry}, instance => $instance);

        next if ($self->check_filter(section => 'logicaldrive', instance => $instance));
        $self->{components}->{logicaldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Logical drive '%s.%s' status is '%s' [instance = %s]",
                                    $result->{logicalDriveRAIDControllerIndex}, $result->{logicalDriveIndex}, $result->{logicalDriveState}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(section => 'logicaldrive', value => $result->{logicalDriveState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Logical drive '%s.%s' status is '%s'", 
                                            $result->{logicalDriveRAIDControllerIndex},
                                            $result->{logicalDriveIndex},
                                            $result->{logicalDriveState}));
        }
    }
}

1;
