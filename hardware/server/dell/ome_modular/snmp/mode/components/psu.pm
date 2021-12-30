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

package hardware::server::dell::ome_modular::snmp::mode::components::psu;

use strict;
use warnings;

my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

# In MIB 'DELL-MM-MIB-SMIv2'
my $mapping = {
    dmmPSULocation   => { oid => '.1.3.6.1.4.1.674.10892.6.4.2.1.3' },
    dmmPSUCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.6.4.2.1.8', map => \%map_status },
};
my $oid_dmmPSUTableEntry = '.1.3.6.1.4.1.674.10892.6.4.2.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, {oid => $oid_dmmPSUTableEntry};
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};

    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_dmmPSUTableEntry}})) {
        next if ($oid !~ /^$mapping->{dmmPSUCurrStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_dmmPSUTableEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf( "Power supply '%s': state %s [instance: %s].",
                            $result->{dmmPSULocation},
                            $result->{dmmPSUCurrStatus},
                            $instance
            )
        );
    }
}

1;
