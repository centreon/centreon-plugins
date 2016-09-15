#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package hardware::server::hp::bladechassis::snmp::mode::components::network;

use strict;
use warnings;

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
    4 => 'Weird!!!', # for blades it can return 4, which is NOT spesified in MIB
);

my %device_type = (
    1 => 'noconnect', 
    2 => 'network',
    3 => 'fibrechannel',
    4 => 'sas',
    5 => 'inifiband',
    6 => 'pciexpress',
);

sub check {
    my ($self) = @_;

    $self->{components}->{network} = {name => 'network connectors', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking network connectors");
    return if ($self->check_exclude(section => 'network'));
    
    my $oid_cpqRackNetConnectorPresent = '.1.3.6.1.4.1.232.22.2.6.1.1.1.13';
    my $oid_cpqRackNetConnectorIndex = '.1.3.6.1.4.1.232.22.2.6.1.1.1.3';
    my $oid_cpqRackNetConnectorModel = '.1.3.6.1.4.1.232.22.2.6.1.1.1.6';
    my $oid_cpqRackNetConnectorSerialNum = '.1.3.6.1.4.1.232.22.2.6.1.1.1.7';
    my $oid_cpqRackNetConnectorPartNumber = '.1.3.6.1.4.1.232.22.2.6.1.1.1.8';
    my $oid_cpqRackNetConnectorSparePartNumber = '.1.3.6.1.4.1.232.22.2.6.1.1.1.9';
    my $oid_cpqRackNetConnectorDeviceType = '.1.3.6.1.4.1.232.22.2.6.1.1.1.17';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackNetConnectorPresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($present_map{$result->{$key}} ne 'present');
        $key =~ /\.([0-9]+)$/;
        my $oid_end = $1;
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cpqRackNetConnectorIndex . "." . $oid_end, $oid_cpqRackNetConnectorModel . "." . $oid_end,
                $oid_cpqRackNetConnectorSerialNum . "." . $oid_end, $oid_cpqRackNetConnectorPartNumber . "." . $oid_end,
                $oid_cpqRackNetConnectorSparePartNumber . "." . $oid_end, $oid_cpqRackNetConnectorDeviceType . "." . $oid_end;
    }
    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $nc_index = $result->{$oid_cpqRackNetConnectorIndex . '.' . $_};
        my $nc_model = $result->{$oid_cpqRackNetConnectorModel . '.' . $_};
        my $nc_serial = $result->{$oid_cpqRackNetConnectorSerialNum . '.' . $_};
        my $nc_part = $result->{$oid_cpqRackNetConnectorPartNumber . '.' . $_};
        my $nc_spare = $result->{$oid_cpqRackNetConnectorSparePartNumber . '.' . $_};
        my $nc_device = $result->{$oid_cpqRackNetConnectorDeviceType . '.' . $_};
        
        next if ($self->check_exclude(section => 'network', instance => $nc_index));
        
        $self->{components}->{network}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Network Connector %d (%s) type '%s' is present [serial: %s, part: %s, spare: %s].",
                                    $nc_index, $nc_model,
                                    $device_type{$nc_device},
                                    $nc_serial, $nc_part, $nc_spare
                                    ));
    }
}

1;