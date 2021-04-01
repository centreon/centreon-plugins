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

package hardware::server::dell::idrac::snmp::mode::components::network;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status);

my $mapping = {
    networkDeviceStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.90.1.3', map => \%map_status },
    networkDeviceProductName    => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.90.1.6' }
};
my $oid_networkDeviceTableEntry = '.1.3.6.1.4.1.674.10892.5.4.1100.90.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_networkDeviceTableEntry,
        start => $mapping->{networkDeviceStatus}->{oid},
        end => $mapping->{networkDeviceProductName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking networks");
    $self->{components}->{network} = {name => 'networks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'network'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_networkDeviceTableEntry}})) {
        next if ($oid !~ /^$mapping->{networkDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_networkDeviceTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'network', instance => $instance));
        $self->{components}->{network}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "network '%s' status is '%s' [instance = %s]",
                $result->{networkDeviceProductName}, $result->{networkDeviceStatus}, $instance
            )
        );

        my $exit = $self->get_severity(label => 'default.status', section => 'network.status', value => $result->{networkDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Network '%s' status is '%s'", $result->{networkDeviceProductName}, $result->{networkDeviceStatus})
            );
        }
    }
}

1;
