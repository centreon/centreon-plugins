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

    $isVeeamAgent=$false 
    $vbrjob=Get-VBRJob 

    if (($vbrjob | Select-Object -first 1).JobType -like "*Agent*") { 
        $isVeeamAgent=$true 
    } else { 
        $isVeeamAgent=$false 
    } 

    $sessions = @{} 

    if ($isVeeamAgent) { 
        Get-VBRComputerBackupJobSession | Sort-Object CreationTime -Descending | ForEach-Object { 
            $jobId = $_.JobId.toString() 
            if (-not $sessions.ContainsKey($jobId)) { 
                $sessions[$jobId] = New-Object System.Collections.Generic.List[Hashtable]; 
                $session = @{}
                $session.result = $_.Result.value__
                $session.creationTimeUTC = (get-date -date $_.CreationTime.ToUniversalTime() -Uformat ' . "'%s'" . ') 
                $session.endTimeUTC = (get-date -date $_.EndTime.ToUniversalTime() -Uformat ' . "'%s'" . ') 
                $sessions[$jobId].Add($session) 
            } elseif ($sessions[$jobId].Length -lt 2) { 
                $session = @{} 
                $session.result = $_.Result.value__
                $session.creationTimeUTC = (get-date -date $_.CreationTime.ToUniversalTime() -Uformat ' . "'%s'" . ') 
                $session.endTimeUTC = (get-date -date $_.EndTime.ToUniversalTime() -Uformat ' . "'%s'" . ') 
                $sessions[$jobId].Add($session) 
            } 
        } 

        Get-VBRComputerBackupJob | ForEach-Object { 
            $item = @{} 
            $item.name = $_.Name 
            $item.type = $_.Type.value__
            $item.isRunning = $false
            $item.scheduled = $_.ScheduleEnabled
            $item.isContinuous = 0

            if ($_.isContinuous -eq $true) { 
                $item.isContinuous = 1 
            } 

            $Id = $_.Id.toString()
            if ($sessions.ContainsKey($Id)) {
                $item.sessions = $sessions[$Id] 
                if ($sessions[$_.Id].State -eq "Running") { 
                    $item.isRunning = $true 
                }  
            } else { 
                $item.sessions = New-Object System.Collections.Generic.List[Hashtable]; 
                $session = @{} 
                $session.result = -10 
                $session.creationTimeUTC = "" 
                $session.endTimeUTC = "" 
                $item.sessions.Add($session) 
            } 

            $items.Add($item) 
        } 

    } else { 
        Get-VBRBackupSession | Sort-Object CreationTimeUTC -Descending | ForEach-Object { 
            $jobId = $_.jobId.toString() 
            if (-not $sessions.ContainsKey($jobId)) { 
                $sessions[$jobId] = New-Object System.Collections.Generic.List[Hashtable]; 
                $session = @{} 
                $session.result = $_.Result.value__ 
                $session.creationTimeUTC = (get-date -date $_.CreationTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ') 
                $session.endTimeUTC = (get-date -date $_.EndTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ')
                $sessions[$jobId].Add($session) 
            } elseif ($sessions[$jobId].Length -lt 2) { 
                $session = @{} 
                $session.result = $_.Result.value__ 
                $session.creationTimeUTC = (get-date -date $_.CreationTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ') 
                $session.endTimeUTC = (get-date -date $_.EndTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ') 
                $sessions[$jobId].Add($session) 
            } 
        } 

        $vbrjob | ForEach-Object { 
            $item = @{} 
            $item.name = $_.Name 
            $item.type = $_.JobType.value__ 
            $item.isRunning = $_.isRunning 
            $item.scheduled = $_.IsScheduleEnabled 
            $item.isContinuous = 0 

            if ($_.isContinuous -eq $true) { 
                $item.isContinuous = 1 
            } 

            $guid = $_.Id.Guid.toString() 
            if ($sessions.ContainsKey($guid)) { 
                $item.sessions = $sessions[$guid] 
            } else { 
                $item.sessions = New-Object System.Collections.Generic.List[Hashtable]; 
                $session = @{} 
                $session.result = -10 
                $session.creationTimeUTC = "" 
                $session.endTimeUTC = "" 
                $item.sessions.Add($session) 
            } 

            $items.Add($item) 
        } 
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
