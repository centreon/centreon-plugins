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

package centreon::common::adic::tape::snmp::mode::components::physicaldrive;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_status = (
    1 => 'good',
    2 => 'failed',
    3 => 'degraded',
    4 => 'warning',
    5 => 'informational',
    6 => 'unknown',
    7 => 'invalid',
);

my $mapping = {
    # 'ADIC-TAPE-LIBRARY-MIB'
    adic_tape => {
        phDriveSerialNumber => { oid => '.1.3.6.1.4.1.3764.1.10.10.11.3.1.2' },
        phDriveModel => { oid => '.1.3.6.1.4.1.3764.1.10.10.11.3.1.3' },
        phDriveRasStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.11.3.1.11', map => \%map_status },
    },
    # 'ADIC-MANAGEMENT-MIB'
    adic_management => { 
        phDriveSerialNumber => { oid => '.1.3.6.1.4.1.3764.1.1.200.20.80.110.1.8' },
        phDriveModel => { oid => '.1.3.6.1.4.1.3764.1.1.200.20.80.110.1.7' }, # phDriveProduct
        phDriveRasStatus => { oid => '.1.3.6.1.4.1.3764.1.1.200.20.80.110.1.31', map => \%map_status },
    }
};

my %oid_table = (
    adic_tape => '.1.3.6.1.4.1.3764.1.10.10.11.3.1', # physicalDriveEntry
    adic_management => '.1.3.6.1.4.1.3764.1.1.200.20.80.110.1', # phDriveEntry
);

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_table{adic_tape} }, { oid => $oid_table{adic_management} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking physical drives");
    $self->{components}->{physicaldrive} = {name => 'physical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'physicaldrive'));
    
    foreach my $label (keys %{$mapping}) {
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_table{$label}}})) {
            next if ($oid !~ /^$mapping->{$label}->{phDriveRasStatus}->{oid}\.(.*)$/);
            my $instance = $1;
            my $result = $self->{snmp}->map_instance(mapping => $mapping->{$label}, results => $self->{results}->{$oid_table{$label}}, instance => $instance);

            $result->{phDriveSerialNumber} = centreon::plugins::misc::trim($result->{phDriveSerialNumber});

            next if ($self->check_filter(section => 'physicaldrive', instance => $result->{phDriveSerialNumber}));
            $self->{components}->{physicaldrive}->{total}++;

            $self->{output}->output_add(long_msg => sprintf("physical drive '%s' status is %s [instance: %s, model: %s, serial: %s].",
                                        $result->{phDriveSerialNumber}, $result->{phDriveRasStatus},
                                        $result->{phDriveSerialNumber}, centreon::plugins::misc::trim($result->{phDriveModel}), 
                                        centreon::plugins::misc::trim($result->{phDriveSerialNumber})
                                        ));
            my $exit = $self->get_severity(section => 'physicaldrive', label => 'default', value => $result->{phDriveRasStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity =>  $exit,
                                            short_msg => sprintf("Physical drive '%s' status is %s",
                                                                 $result->{phDriveSerialNumber}, $result->{phDriveRasStatus}));
            }
        }
    }
}

1;