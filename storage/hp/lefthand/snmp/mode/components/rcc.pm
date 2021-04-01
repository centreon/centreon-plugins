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

package storage::hp::lefthand::snmp::mode::components::rcc;

use strict;
use warnings;
use storage::hp::lefthand::snmp::mode::components::resources qw($map_status);

my $mapping = {
    infoCacheName       => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.2' },
    infoCacheBbuState   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.22' },
    infoCacheBbuStatus  => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.23', map => $map_status },
    infoCacheEnabled    => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.50' },
    infoCacheState      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.90' },
    infoCacheStatus     => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.91', map => $map_status },
};
my $oid_infoCacheEntry = '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_infoCacheEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking raid controller caches");
    $self->{components}->{rcc} = {name => 'raid controller caches', total => 0, skip => 0};
    return if ($self->check_filter(section => 'rcc'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_infoCacheEntry}})) {
        next if ($oid !~ /^$mapping->{infoCacheStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_infoCacheEntry}, instance => $instance);

        next if ($self->check_filter(section => 'rcc', instance => $instance));
        $self->{components}->{rcc}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("raid controller cache '%s' status is '%s' [instance: %s, state: %s].",
                                    $result->{infoCacheName}, $result->{infoCacheStatus},
                                    $instance, $result->{infoCacheState}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'rcc', value => $result->{infoCacheStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("raid controller cache '%s' state is '%s'",
                                                             $result->{infoCacheName}, $result->{infoCacheState}));
        }
        
        next if ($result->{infoCacheEnabled} != 1);
        
        $self->{output}->output_add(long_msg => sprintf("bbu '%s' status is '%s' [instance: %s, state: %s].",
                                    $result->{infoCacheName}, $result->{infoCacheBbuStatus},
                                    $instance, $result->{infoCacheBbuState}
                                    ));
        $exit = $self->get_severity(label => 'default', section => 'bbu', value => $result->{infoCacheBbuStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("bbu '%s' state is '%s'",
                                                             $result->{infoCacheName}, $result->{infoCacheBbuState}));
        }
    }
}

1;