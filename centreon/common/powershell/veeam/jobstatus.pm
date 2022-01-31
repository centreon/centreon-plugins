#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::veeam::jobstatus;

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
    Get-VBRBackupSession | Sort CreationTimeUTC -Descending | ForEach-Object {
        if ($null -eq $sessions[$_.jobId]) {
            $sessions[$_.jobId] = @{}
            $sessions[$_.jobId].result = $_.Result.value__
            $sessions[$_.jobId].creationTimeUTC = (get-date -date $_.CreationTime.ToUniversalTime() -Uformat ' . "'%s'" . ')
            $sessions[$_.jobId].endTimeUTC = (get-date -date $_.EndTime.ToUniversalTime() -Uformat ' . "'%s'" . ')
        }
    }

    $jobs = Get-VBRJob
    foreach ($job in $jobs) {
        $item = @{}
        $item.name = $job.Name
        $item.type = $job.JobType.value__
        $item.isRunning = $job.isRunning
        $item.result = -10
        $item.creationTimeUTC = ""
        $item.endTimeUTC = ""

        if ($null -ne $sessions[$job.Id.Guid]) {
            $item.result = $sessions[$job.Id.Guid].result
            $item.creationTimeUTC = $sessions[$job.Id.Guid].creationTimeUTC
            $item.endTimeUTC = $sessions[$job.Id.Guid].endTimeUTC
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

Method to get veeam job status informations.

=cut
