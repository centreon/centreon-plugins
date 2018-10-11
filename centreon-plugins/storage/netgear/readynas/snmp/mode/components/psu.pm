#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Author : ArnoMLT
#

package storage::netgear::readynas::snmp::mode::components::psu;

use strict;
use warnings;

my ($mapping, $oid_psuTable);

my $mapping_v6 = {
    psuStatus => { oid => '.1.3.6.1.4.1.4526.22.8.1.3' },
};
my $oid_psuTable_v6 = '.1.3.6.1.4.1.4526.22.8';

my $mapping_v4 = {
    psuStatus => { oid => '.1.3.6.1.4.1.4526.18.8.1.3' },
};
my $oid_psuTable_v4 = '.1.3.6.1.4.1.4526.18.8';

sub load {
    my ($self) = @_;
    
	$mapping = $self->{mib_ver} == 4 ? $mapping_v4 : $mapping_v6;
	$oid_psuTable = $self->{mib_ver} == 4 ? $oid_psuTable_v4 : $oid_psuTable_v6;
	
    push @{$self->{request}}, { oid => $oid_psuTable };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supply");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_psuTable}})) {
        next if ($oid !~ /^$mapping->{psuStatus}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_psuTable}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is %s.",
                                    $instance, $result->{psuStatus}));
		my $exit = $self->get_severity(section => 'psu', value => $result->{psuStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' status is %s.", $instance, $result->{psuStatus}));
        }
    }
}

1;