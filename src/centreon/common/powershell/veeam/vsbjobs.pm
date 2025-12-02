#
# Copyright 2025 Centreon (http://www.centreon.com/)
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
use version;

sub get_powershell {
    my (%options) = @_;

    # if veeam_version is 12 or higher, the functions used are different from the previous versions
    my ($get_session_cmd, $get_job_cmd, $job_id, $guid, $creation_time, $end_time, $sure_backup_job_result, $sure_backup_job_type);
    # parsing versions x.y.z can be tedious, we rely on the `version` standard module
    if (version->parse($options{veeam_version}) >= 12) {
        $get_session_cmd        = 'Get-VBRSureBackupSession';
        $get_job_cmd            = 'Get-VBRSureBackupJob';
        $job_id                 = 'JobId';
        $guid                   = '';
        $creation_time          = 'CreationTime';
        $end_time               = 'EndTime';
        # Veeam >= 12 job result mapping is
        # 0 => 'none'
        # 1 => 'success'
        # 2 => 'warning'
        # 3 => 'failed'
        $sure_backup_job_result = ' - 1';
        $sure_backup_job_type = '$item.type = "SureBackup"'; # Job Type is not returned with Get-VBRSureBackupJob whereas it is with Get-VSBJob
    } else {
        $get_session_cmd        = 'Get-VSBSession';
        $get_job_cmd            = 'Get-VSBJob';
        $job_id                 = 'jobId';
        $guid                   = '.Guid';
        $creation_time          = 'CreationTimeUTC';
        $end_time               = 'EndTimeUTC';
        # Veeam < 12 job result mapping is 
        # 0 => 'success
        # 1 => 'warning'
        # 2 => 'failed'
        # -1 => 'none'
        $sure_backup_job_result = '';
        $sure_backup_job_type   = '$item.type = $_.JobType.value__';
    }

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
    ' . $get_session_cmd . ' | Sort ' . $creation_time . ' -Descending | ForEach-Object {
        $jobId = $_.' . $job_id . '.toString()
        if (-not $sessions.ContainsKey($jobId)) {
            $sessions[$jobId] = @{}
            $sessions[$jobId].result = $_.Result.value__' . $sure_backup_job_result . '
            $sessions[$jobId].creationTimeUTC = (get-date -date $_.' . $creation_time . '.ToUniversalTime() -Uformat ' . "'%s'" . ')
            $sessions[$jobId].endTimeUTC = (get-date -date $_.' . $end_time . '.ToUniversalTime() -Uformat ' . "'%s'" . ')
        }
    }

    ' . $get_job_cmd . ' | ForEach-Object {
        $item = @{}
        $item.name = $_.Name
        ' . $sure_backup_job_type . ' 
        $item.result = -10
        $item.creationTimeUTC = ""
        $item.endTimeUTC = ""

        $guid = $_.Id' . $guid .  '.toString()
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

Method to get Veeam SureBackup jobs information.

=cut
