#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::hyperv::2012::scvmmdiscovery;

use strict;
use warnings;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;

    my $hostname = '$env:computername';
    if (defined($options{scvmm_hostname}) && $options{scvmm_hostname} ne '') {
        $hostname = '"' . $options{scvmm_hostname} . '"';
    }
    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);

    $ps .= '
$ProgressPreference = "SilentlyContinue"

Try {
    $ErrorActionPreference = "Stop"
    Import-Module -Name "virtualmachinemanager" 

    $username = "' . $options{scvmm_username} . '"
    $password = ConvertTo-SecureString "' . $options{scvmm_password} . '" -AsPlainText -Force
    $UserCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$password

    $connection = Get-VMMServer -ComputerName ' . $hostname . ' -TCPPort ' . $options{scvmm_port} . ' -Credential $UserCredential
    $vms = Get-SCVirtualMachine -VMMServer $connection

    $items = New-Object System.Collections.Generic.List[Hashtable];
    Foreach ($vm in $vms) {
        $item = @{}

        $item.type = "vm"
        $item.vmId = $vm.VMId
        $item.name = $vm.Name
        $desc = $vm.Description -replace "\r",""
        $item.description = $desc
        $item.operatingSystem = $vm.OperatingSystem.ToString()
        $item.status = $vm.Status.value__
        $item.hostGroupPath = $vm.HostGroupPath
        $item.enabled = $vm.enabled
        $item.computerName = $vm.ComputerName
        $item.tag = $vm.Tag
        $item.vmHostId = $vm.VMHost.ID.Guid

        $ipv4Addresses = @()
        if ($vm.Status -eq "Running") {
            Foreach ($adapter in $vm.VirtualNetworkAdapters) {
                $ipv4Addresses += $adapter.IPv4Addresses
            }
        }
        $item.ipv4Addresses = $ipv4Addresses

        $items.Add($item)
    }

    $vmhosts = Get-SCVmHost -VMMServer $connection
    Foreach ($vmhost in $vmhosts) {
        $item = @{}

        $item.type = "host"
        $item.id = $vmhost.ID.Guid
        $item.name = $vmhost.Name
        $desc = $host.Description -replace "\r",""
        $item.description = $desc
        $item.FQDN = $vmhost.FQDN
        $item.clusterName = $vmhost.HostCluster.Name
        $item.operatingSystem = $vmhost.OperatingSystem.Name

        $items.Add($item)
    }

    $jsonString = $items | ConvertTo-JSON-20 -forceArray $true
    Write-Host $jsonString
} Catch {
    Write-Host $Error[0].Exception
    exit 1
}

exit 0
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Method to get hyper-v informations.

=cut
