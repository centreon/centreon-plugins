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

package hardware::server::ibm::bladecenter::snmp::mode::components::chassisstatus;

use strict;
use warnings;

# In MIB 'mmblade.mib' and 'cme.mib'
my $oid_mmBistAndChassisStatus = '.1.3.6.1.4.1.2.3.51.2.2.5.2';
my $oid_bistLogicalNetworkLink = '.1.3.6.1.4.1.2.3.51.2.2.5.2.30.0';
my $oids = {
    bistSdram                       => '.1.3.6.1.4.1.2.3.51.2.2.5.2.1.0',
    bistRs485Port1                  => '.1.3.6.1.4.1.2.3.51.2.2.5.2.2.0',
    bistRs485Port2                  => '.1.3.6.1.4.1.2.3.51.2.2.5.2.3.0',
    bistNvram                       => '.1.3.6.1.4.1.2.3.51.2.2.5.2.4.0',
    bistRtc                         => '.1.3.6.1.4.1.2.3.51.2.2.5.2.5.0',
    bistLocalI2CBus                 => '.1.3.6.1.4.1.2.3.51.2.2.5.2.7.0',
    bistPrimaryMainAppFlashImage    => '.1.3.6.1.4.1.2.3.51.2.2.5.2.8.0',
    bistSecondaryMainAppFlashImage  => '.1.3.6.1.4.1.2.3.51.2.2.5.2.9.0',
    bistBootRomFlashImage           => '.1.3.6.1.4.1.2.3.51.2.2.5.2.10.0',
    bistEthernetPort1               => '.1.3.6.1.4.1.2.3.51.2.2.5.2.11.0',
    bistEthernetPort2               => '.1.3.6.1.4.1.2.3.51.2.2.5.2.12.0',
    bistInternalPCIBus              => '.1.3.6.1.4.1.2.3.51.2.2.5.2.13.0',
    bistExternalI2CDevices          => '.1.3.6.1.4.1.2.3.51.2.2.5.2.14.0',
    bistUSBController               => '.1.3.6.1.4.1.2.3.51.2.2.5.2.15.0',
    bistVideoCompressorBoard        => '.1.3.6.1.4.1.2.3.51.2.2.5.2.16.0',
    bistRemoteVideo                 => '.1.3.6.1.4.1.2.3.51.2.2.5.2.17.0',
    bistPrimaryBus                  => '.1.3.6.1.4.1.2.3.51.2.2.5.2.18.0',
    bistInternalEthernetSwitch      => '.1.3.6.1.4.1.2.3.51.2.2.5.2.19.0',
    bistVideoCapture                => '.1.3.6.1.4.1.2.3.51.2.2.5.2.20.0',
    bistUSBKeyboardMouseEmulation   => '.1.3.6.1.4.1.2.3.51.2.2.5.2.21.0',
    bistUSBMassStorageEmulation     => '.1.3.6.1.4.1.2.3.51.2.2.5.2.22.0',
    bistUSBKeyboardMouseFirmware    => '.1.3.6.1.4.1.2.3.51.2.2.5.2.23.0',
    bistUSBMassStorageFirmware      => '.1.3.6.1.4.1.2.3.51.2.2.5.2.24.0',
    bistPrimaryCore                 => '.1.3.6.1.4.1.2.3.51.2.2.5.2.25.0',
    bistSecondaryCore               => '.1.3.6.1.4.1.2.3.51.2.2.5.2.26.0',
    bistInternalIOExpander          => '.1.3.6.1.4.1.2.3.51.2.2.5.2.27.0',
    bistRemoteControlFirmware       => '.1.3.6.1.4.1.2.3.51.2.2.5.2.28.0',
    bistPhysicalNetworkLink         => '.1.3.6.1.4.1.2.3.51.2.2.5.2.29.0',
    bistLogicalNetworkLink          => '.1.3.6.1.4.1.2.3.51.2.2.5.2.30.0',
};

my %map_test_state = (
    0 => 'testSucceeded',
    1 => 'testFailed',
);

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_mmBistAndChassisStatus, end => $oid_bistLogicalNetworkLink };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking chassis status");
    $self->{components}->{chassisstatus} = {name => 'chassis-status', total => 0, skip => 0};
    return if ($self->check_filter(section => 'chassisstatus'));

    foreach my $name (sort keys %{$oids}) {
        if (!defined($self->{results}->{$oid_mmBistAndChassisStatus}->{$oids->{$name}})) {
            $self->{output}->output_add(long_msg => sprintf("skip '%s': no value", 
                                                             $name));
            next;
        }
        
        my $value = $map_test_state{$self->{results}->{$oid_mmBistAndChassisStatus}->{$oids->{$name}}};
        next if ($self->check_filter(section => 'chassisstatus', instance => $name));
        $self->{components}->{chassisstatus}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Chassis status '%s' state is %s", 
                                                        $name, $value));
        my $exit = $self->get_severity(section => 'chassisstatus', value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Chassis status '%s' state is %s", 
                                                             $name, $value));
        }
    }
}

1;