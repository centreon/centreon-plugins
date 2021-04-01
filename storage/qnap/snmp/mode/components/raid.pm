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

package storage::qnap::snmp::mode::components::raid;

use strict;
use warnings;

# In MIB 'NAS.mib'
my $oid_raidStatus = '.1.3.6.1.4.1.24681.1.4.1.1.1.2.1.2.1.5';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_raidStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raids");
    $self->{components}->{raid} = {name => 'raids', total => 0, skip => 0};
    return if ($self->check_filter(section => 'raid'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raidStatus}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;

        next if ($self->check_filter(section => 'raid', instance => $instance));
        
        my $status = $self->{results}->{$oid_raidStatus}->{$oid};
        $self->{components}->{raid}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "raid '%s' status is %s [instance: %s]",
                $instance, $status, $instance
            )
        );
        my $exit = $self->get_severity(section => 'raid', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Raid '%s' status is %s.", $instance, $status
                )
            );
        }
    }
}

1;
