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

my $mapping = {
    nc_model    => { oid => '.1.3.6.1.4.1.232.22.2.6.1.1.1.6' }, # cpqRackNetConnectorModel
    nc_serial   => { oid => '.1.3.6.1.4.1.232.22.2.6.1.1.1.7' }, # cpqRackNetConnectorSerialNum
    nc_part     => { oid => '.1.3.6.1.4.1.232.22.2.6.1.1.1.8' }, # cpqRackNetConnectorPartNumber
    nc_spare    => { oid => '.1.3.6.1.4.1.232.22.2.6.1.1.1.9' }, # cpqRackNetConnectorSparePartNumber
    nc_device   => { oid => '.1.3.6.1.4.1.232.22.2.6.1.1.1.17', map => \%device_type }, # cpqRackNetConnectorDeviceType
};

sub check {
    my ($self) = @_;

    $self->{components}->{network} = {name => 'network connectors', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "checking network connectors");
    return if ($self->check_filter(section => 'network'));
    
    my $oid_cpqRackNetConnectorPresent = '.1.3.6.1.4.1.232.22.2.6.1.1.1.13';
    
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_cpqRackNetConnectorPresent);
    return if (scalar(keys %$snmp_result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($present_map{$snmp_result->{$key}} ne 'present');
        $key =~ /^$oid_cpqRackNetConnectorPresent\.(.*)$/;
        my $oid_end = $1;
        
        push @oids_end, $oid_end;
        push @get_oids, map($_->{oid} . '.' . $oid_end, values(%$mapping));
    }
    $snmp_result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $nc_index = $_;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        next if ($self->check_filter(section => 'network', instance => $nc_index));
        
        $self->{components}->{network}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf("network connector '%s' (%s) type '%s' is present [serial: %s, part: %s, spare: %s].",
                $nc_index, $result->{nc_model},
                $result->{nc_device},
                $result->{nc_serial}, $result->{nc_part}, $result->{nc_spare}
            )
        );
    }
}

1;
