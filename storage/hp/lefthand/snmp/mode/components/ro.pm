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

package storage::hp::lefthand::snmp::mode::components::ro;

use strict;
use warnings;

my $mapping = {
    storageOsRaidName   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.51.1.2' },
    storageOsRaidState  => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.51.1.90' },
};
my $oid_storageOsRaidEntry = '.1.3.6.1.4.1.9804.3.1.1.2.4.51.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_storageOsRaidEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking raid os devices");
    $self->{components}->{ro} = {name => 'raid os devices', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ro'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_storageOsRaidEntry}})) {
        next if ($oid !~ /^$mapping->{storageOsRaidState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_storageOsRaidEntry}, instance => $instance);

        next if ($self->check_filter(section => 'ro', instance => $instance));
        $self->{components}->{ro}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("raid device controller '%s' state is '%s' [instance: %s].",
                                    $result->{storageOsRaidName}, $result->{storageOsRaidState},
                                    $instance
                                    ));
        my $exit = $self->get_severity(label => 'default2', section => 'ro', value => $result->{storageOsRaidState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("raid device controller '%s' state is '%s'",
                                                             $result->{storageOsRaidName}, $result->{storageOsRaidState}));
        }
    }
}

1;