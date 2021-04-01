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

package storage::lenovo::iomega::snmp::mode::components::raid;

use strict;
use warnings;

my $mapping = {
    raidStatus => { oid => '.1.3.6.1.4.1.11369.10.4.1' }
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{raidStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking raids');
    $self->{components}->{raid} = { name => 'raids', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'raid'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{raidStatus}->{oid} }, instance => '0');
    return if (!defined($result->{raidStatus}));

    my $instance = 1;
    next if ($self->check_filter(section => 'raid', instance => $instance));
    $self->{components}->{raid}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "raid '%s' status is '%s' [instance = %s]",
            $instance, $result->{raidStatus}, $instance
        )
    );
    my $exit = $self->get_severity(section => 'raid', value => $result->{raidStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Raid '%s' status is '%s'", $instance, $result->{raidStatus}
            )
        );
    }
}

1;
