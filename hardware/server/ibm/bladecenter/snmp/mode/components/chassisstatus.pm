################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package hardware::server::ibm::bladecenter::snmp::mode::components::chassisstatus;

use strict;
use warnings;

# In MIB 'mmblade.mib'
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
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_mmBistAndChassisStatus, end => $oid_bistLogicalNetworkLink };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking chassis status");
    $self->{components}->{chassisstatus} = {name => 'chassis-status', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'chassisstatus'));

    foreach my $name (sort keys %{$oids}) {
        if (!defined($self->{results}->{$oid_mmBistAndChassisStatus}->{$oids->{$name}})) {
            $self->{output}->output_add(long_msg => sprintf("skip '%s': no value", 
                                                             $name));
            next;
        }
        
        my $value = $map_test_state{$self->{results}->{$oid_mmBistAndChassisStatus}->{$oids->{$name}}};
        next if ($self->check_exclude(section => 'chassisstatus', instance => $name));
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