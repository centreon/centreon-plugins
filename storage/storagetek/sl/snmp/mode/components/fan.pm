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

package storage::storagetek::sl::snmp::mode::components::fan;

use strict;
use warnings;
use storage::storagetek::sl::snmp::mode::components::resources qw($map_operational);

my $mapping = {
    slHdwFanName        => { oid => '.1.3.6.1.4.1.1211.1.15.4.6.1.2' },
    slHdwFanOperational => { oid => '.1.3.6.1.4.1.1211.1.15.4.6.1.3', map => $map_operational },
};
my $oid_slHdwFanEntry = '.1.3.6.1.4.1.1211.1.15.4.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_slHdwFanEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_slHdwFanEntry}})) {
        next if ($oid !~ /^$mapping->{slHdwFanOperational}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_slHdwFanEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance: %s].",
                                    $result->{slHdwFanName}, $result->{slHdwFanOperational},
                                    $instance
                                    ));
        my $exit = $self->get_severity(label => 'operational', section => 'fan', value => $result->{slHdwFanOperational});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'",
                                                             $result->{slHdwFanName}, $result->{slHdwFanOperational}));
        }
    }
}

1;