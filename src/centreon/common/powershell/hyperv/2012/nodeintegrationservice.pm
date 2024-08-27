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

package centreon::common::powershell::hyperv::2012::nodeintegrationservice;

use strict;
use warnings;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;

    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);

    # if the version of HyperV Powershell module is higher than 2.0.0 and not compatible with
    # the following script, then use this Import-Module instead:
    # Import-Module -Name "Hyper-V" -MaximumVersion "2.0.0"
    $ps .= '
$ProgressPreference = "SilentlyContinue"

Try {
    $ErrorActionPreference = "Stop"
    If (@(Get-Module | Where-Object {$_.Name -Match "Hyper-V"} ).count -eq 0) {
        Import-Module -Name "Hyper-V"
    }

    $vms = Get-VM

    $items = New-Object System.Collections.Generic.List[Hashtable];
    Foreach ($vm in $vms) {
        $item = @{}

        $note = $vm.Notes -replace "\r",""
        $note = $note -replace "\n"," - "

        $item.name = $vm.VMName
        $item.state = $vm.State.value__
        $item.integration_services_state = $vm.IntegrationServicesState
        $item.integration_services_version = $null
        if ($null -ne $vm.IntegrationServicesVersion) {
            $item.integration_services_version = $vm.IntegrationServicesVersion.toString()
        }
        $item.note = $note

        $services = New-Object System.Collections.Generic.List[Hashtable];
        Foreach ($service in $vm.VMIntegrationService) {
            $item_service = @{}

            $item_service.service = $service.Name
            $item_service.enabled = $service.Enabled

            # this works for sure on v1.1 of HyperV Powershell module
            $item_service.primary_operational_status = $service.PrimaryOperationalStatus.value__
            $item_service.secondary_operational_status = $service.SecondaryOperationalStatus.value__

            # this works for sure on v2.0.0 of HyperV Powershell module
            if (($service.PrimaryStatusDescription -ne $null) -and ($service.PrimaryStatusDescription -ne "")) {
                $item_service.primary_operational_status = $service.PrimaryStatusDescription
            }
            if (($service.SecondaryStatusDescription -ne $null) -and ($service.SecondaryStatusDescription -ne "")) {
                $item_service.secondary_operational_status = $service.SecondaryStatusDescription
            }

            $services.Add($item_service)
        }

        $item.services = $services
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

Method to get Hyper-V information.

=cut
