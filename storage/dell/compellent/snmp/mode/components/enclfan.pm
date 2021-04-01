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

package storage::dell::compellent::snmp::mode::components::enclfan;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scEnclFanStatus     => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.20.1.3', map => \%map_sc_status },
    scEnclFanLocation   => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.20.1.4' },
};
my $oid_scEnclFanEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.20.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scEnclFanEntry, begin => $mapping->{scEnclFanStatus}->{oid}, end => $mapping->{scEnclFanLocation}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking enclosure fans");
    $self->{components}->{enclfan} = {name => 'enclosure fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'enclfan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scEnclFanEntry}})) {
        next if ($oid !~ /^$mapping->{scEnclFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scEnclFanEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'enclfan', instance => $instance));
        $self->{components}->{enclfan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("enclosure fan '%s' status is '%s' [instance = %s]",
                                    $result->{scEnclFanLocation}, $result->{scEnclFanStatus}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default', section => 'enclfan', value => $result->{scEnclFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Enclosure fan '%s' status is '%s'", $result->{scEnclFanLocation}, $result->{scEnclFanStatus}));
        }
    }
}

1;