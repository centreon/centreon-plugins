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

package centreon::common::powershell::veeam::vsbjobs;

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

    $sessions = @{}
    Get-VSBSession | Sort CreationTimeUTC -Descending | ForEach-Object {
        $jobId = $_.jobId.toString()
        if (-not $sessions.ContainsKey($jobId)) {
            $sessions[$jobId] = @{}
            $sessions[$jobId].result = $_.Result.value__
            $sessions[$jobId].creationTimeUTC = (get-date -date $_.CreationTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ')
            $sessions[$jobId].endTimeUTC = (get-date -date $_.EndTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ')
        }
    }

    Get-VSBJob | ForEach-Object {
        $item = @{}
        $item.name = $_.Name
        $item.type = $_.JobType.value__
        $item.result = -10
        $item.creationTimeUTC = ""
        $item.endTimeUTC = ""

        $guid = $_.Id.Guid.toString()
        if ($sessions.ContainsKey($guid)) {
            $item.result = $sessions[$guid].result
            $item.creationTimeUTC = $sessions[$guid].creationTimeUTC
            $item.endTimeUTC = $sessions[$guid].endTimeUTC
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

Method to get veeam SureBackup jobs informations.

=cut
