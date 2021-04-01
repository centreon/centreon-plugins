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

package centreon::common::bluearc::snmp::mode::components::sysdrive;

use strict;
use warnings;

my %map_status = (
    1 => 'online', 2 => 'corrupt', 3 => 'failed',
    4 => 'notPresent', 5 => 'disconnected',
    6 => 'offline', 7 => 'initializing',
    8 => 'formatting', 9 => 'unknown',
);

my $mapping = {
    sysDriveWWN     => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.3.4.2.1.2' },
    sysDriveStatus  => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.3.4.2.1.4', map => \%map_status },
};
my $oid_sysDriveEntry = '.1.3.6.1.4.1.11096.6.1.1.1.3.4.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sysDriveEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking system drives");
    $self->{components}->{sysdrive} = {name => 'sysdrives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sysdrive'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_sysDriveEntry}})) {
        next if ($oid !~ /^$mapping->{sysDriveStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sysDriveEntry}, instance => $instance);

        next if ($self->check_filter(section => 'sysdrive', instance => $result->{sysDriveWWN}));
        $self->{components}->{sysdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("system drive '%s' status is '%s' [instance: %s].",
                                    $result->{sysDriveWWN}, $result->{sysDriveStatus},
                                    $result->{sysDriveWWN}
                                    ));
        my $exit = $self->get_severity(section => 'sysdrive', value => $result->{sysDriveStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("System drive '%s' status is '%s'",
                                                             $result->{sysDriveWWN}, $result->{sysDriveStatus}));
        }
    }
}

1;