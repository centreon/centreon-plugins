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

package centreon::common::powershell::veeam::licenses;

use strict;
use warnings;
use centreon::common::powershell::functions;
use centreon::common::powershell::veeam::functions;

sub get_powershell {
    my (%options) = @_;

    my $ps = '
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);
    $ps .= centreon::common::powershell::veeam::functions::powershell_init();

    $ps .= '
Try {
    $ErrorActionPreference = "Stop"

    $items = New-Object System.Collections.Generic.List[Hashtable];

    $licenses = Get-VBRInstalledLicense
    foreach ($license in $licenses) {
        $item = @{
            licensed_to = $license.LicensedTo;
            type = $license.Type.value__;
            status = $license.Status.value__;
            expiration_time = $null;
            licensed_instances = $null;
            used_instances = $null
        }
        if ($null -ne $license.InstanceLicenseSummary) {
            $item.licensed_instances = $license.InstanceLicenseSummary.LicensedInstancesNumber
            $item.used_instances = $license.InstanceLicenseSummary.UsedInstancesNumber
        }
        if ($null -ne $license.ExpirationDate) {
            $item.expiration_time = (get-date -date $license.ExpirationDate.ToUniversalTime() -UFormat ' . "'%s'" . ')
        }

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

Method to get veeam licenses informations.

=cut
